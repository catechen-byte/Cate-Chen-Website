import type { Metadata } from "next";
import { PageHeader, PageShell } from "@/components/page-shell";

export const metadata: Metadata = {
  title: "About",
  description: "About Cate Chen — research interests, background, and what this site is for.",
};

export default function AboutPage() {
  return (
    <>
      <PageHeader
        title="About"
        description="Research-minded builder working at the intersection of economics, AI, and social policy."
      />
      <PageShell narrow>
        <div className="prose">
          <p>
            I&apos;m Cate Chen. I use quantitative methods — microsimulation, causal inference, and
            interactive tools — to study questions about welfare, labor markets, and technology.
          </p>
          <p>
            This site is my home base for sharing coding projects, research notes, and blog posts.
            Content is written in Markdown/MDX in the repo and deployed through Vercel.
          </p>
          <h2>Focus areas</h2>
          <ul>
            <li>Social welfare and inequality</li>
            <li>AI exposure and labor-market transitions</li>
            <li>Reproducible research workflows in R and TypeScript</li>
          </ul>
          <p>
            Want to connect? Head to the <a href="/contact">contact page</a>.
          </p>
        </div>
      </PageShell>
    </>
  );
}
