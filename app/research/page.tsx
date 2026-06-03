import type { Metadata } from "next";
import { ContentCard } from "@/components/content-card";
import { PageHeader, PageShell } from "@/components/page-shell";
import { getAllContent } from "@/lib/content";

export const metadata: Metadata = {
  title: "Research",
  description: "Research notes, working papers, and methodological writeups.",
};

export default function ResearchPage() {
  const items = getAllContent("research");

  return (
    <>
      <PageHeader
        title="Research"
        description="Longer-form notes on methods, results, and open questions."
      />
      <PageShell>
        <div className="grid gap-6 md:grid-cols-2">
          {items.map((item) => (
            <ContentCard
              key={item.slug}
              href={`/research/${item.slug}`}
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
