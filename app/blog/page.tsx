import type { Metadata } from "next";
import { ContentCard } from "@/components/content-card";
import { PageHeader, PageShell } from "@/components/page-shell";
import { getAllContent } from "@/lib/content";

export const metadata: Metadata = {
  title: "Blog",
  description: "Essays and notes on research, code, and policy.",
};

export default function BlogPage() {
  const posts = getAllContent("blog");

  return (
    <>
      <PageHeader title="Blog" description="Shorter posts and updates — edited as Markdown in the repo." />
      <PageShell>
        <div className="grid gap-6">
          {posts.map((item) => (
            <ContentCard
              key={item.slug}
              href={`/blog/${item.slug}`}
              title={item.title}
              date={item.date}
              summary={item.summary}
              tags={item.tags}
            />
          ))}
        </div>
      </PageShell>
    </>
  );
}
