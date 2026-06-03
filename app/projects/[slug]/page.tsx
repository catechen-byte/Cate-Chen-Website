import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { MdxContent } from "@/components/mdx-content";
import { ButtonLink, PageShell } from "@/components/page-shell";
import { formatDate, getAllContent, getContentBySlug } from "@/lib/content";

type Props = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  return getAllContent("projects").map((item) => ({ slug: item.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const item = getContentBySlug("projects", slug);
  if (!item) return {};
  return { title: item.title, description: item.summary };
}

export default async function ProjectDetailPage({ params }: Props) {
  const { slug } = await params;
  const item = getContentBySlug("projects", slug);
  if (!item) notFound();

  return (
    <PageShell narrow>
      <article className="py-12">
        <p className="text-sm text-[var(--color-muted)]">{formatDate(item.date)}</p>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight">{item.title}</h1>
        <p className="mt-4 text-lg text-[var(--color-muted)]">{item.summary}</p>
        <div className="mt-6 flex flex-wrap gap-3">
          {item.pdf ? <ButtonLink href={item.pdf} external>Download PDF</ButtonLink> : null}
          {item.github ? <ButtonLink href={item.github} external>GitHub</ButtonLink> : null}
          {item.demo ? <ButtonLink href={item.demo} external>Live demo</ButtonLink> : null}
        </div>
        <div className="prose mt-10">
          <MdxContent source={item.content} />
        </div>
      </article>
    </PageShell>
  );
}
