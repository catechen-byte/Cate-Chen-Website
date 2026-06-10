import type { Metadata } from "next";
import { ContentCard } from "@/components/content-card";
import { PageHeader, PageShell } from "@/components/page-shell";
import { getAllContent } from "@/lib/content";
 
export const metadata: Metadata = {
  title: "Projects",
  description: "Coding and research projects with writeups, demos, and downloadable artifacts.",
};

export default function ProjectsPage() {
  const projects = getAllContent("projects");

  return (
    <>
      <PageHeader
        title="Projects"
        description="Applied economics, data tools, and reproducible analysis — with notes on methods and outputs."
      />
      <PageShell>
        <div className="grid gap-6 md:grid-cols-2">
          {projects.map((item) => (
            <ContentCard
              key={item.slug}
              href={`/projects/${item.slug}`}
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
