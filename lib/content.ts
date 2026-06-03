import fs from "fs";
import path from "path";
import matter from "gray-matter";
import { z } from "zod";

export type ContentKind = "blog" | "projects" | "research";

const baseSchema = z.object({
  title: z.string(),
  date: z.string(),
  summary: z.string(),
  tags: z.array(z.string()).default([]),
  draft: z.boolean().default(false),
});

const projectSchema = baseSchema.extend({
  github: z.string().url().optional(),
  demo: z.string().url().optional(),
  pdf: z.string().optional(),
});

const researchSchema = baseSchema.extend({
  citation: z.string().optional(),
  abstract: z.string().optional(),
  pdf: z.string().optional(),
});

export type ContentItem = {
  slug: string;
  kind: ContentKind;
  title: string;
  date: string;
  summary: string;
  tags: string[];
  draft: boolean;
  github?: string;
  demo?: string;
  pdf?: string;
  citation?: string;
  abstract?: string;
  content: string;
};

function contentDir(kind: ContentKind) {
  return path.join(process.cwd(), "content", kind);
}

function parseFrontmatter(kind: ContentKind, slug: string, raw: string): ContentItem {
  const { data, content } = matter(raw);
  const schema = kind === "projects" ? projectSchema : kind === "research" ? researchSchema : baseSchema;
  const parsed = schema.parse(data);

  return {
    slug,
    kind,
    title: parsed.title,
    date: parsed.date,
    summary: parsed.summary,
    tags: parsed.tags,
    draft: parsed.draft,
    content,
    ...(kind === "projects" && {
      github: (parsed as z.infer<typeof projectSchema>).github,
      demo: (parsed as z.infer<typeof projectSchema>).demo,
      pdf: (parsed as z.infer<typeof projectSchema>).pdf,
    }),
    ...(kind === "research" && {
      citation: (parsed as z.infer<typeof researchSchema>).citation,
      abstract: (parsed as z.infer<typeof researchSchema>).abstract,
      pdf: (parsed as z.infer<typeof researchSchema>).pdf,
    }),
  };
}

export function getAllContent(kind: ContentKind, includeDrafts = false): ContentItem[] {
  const dir = contentDir(kind);
  if (!fs.existsSync(dir)) return [];

  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".md") || f.endsWith(".mdx"));

  return files
    .map((file) => {
      const slug = file.replace(/\.mdx?$/, "");
      const raw = fs.readFileSync(path.join(dir, file), "utf8");
      return parseFrontmatter(kind, slug, raw);
    })
    .filter((item) => includeDrafts || !item.draft)
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

export function getContentBySlug(kind: ContentKind, slug: string): ContentItem | null {
  const dir = contentDir(kind);
  for (const ext of [".mdx", ".md"]) {
    const filePath = path.join(dir, `${slug}${ext}`);
    if (fs.existsSync(filePath)) {
      const raw = fs.readFileSync(filePath, "utf8");
      return parseFrontmatter(kind, slug, raw);
    }
  }
  return null;
}

export function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}
