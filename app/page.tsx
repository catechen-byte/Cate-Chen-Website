import Link from "next/link";
import { ContentCard } from "@/components/content-card";
import { ButtonLink, PageShell } from "@/components/page-shell";
import { getAllContent } from "@/lib/content";

export default function HomePage() {
  const projects = getAllContent("projects").slice(0, 2);
  const posts = getAllContent("blog").slice(0, 2);

  return (
    <>
      <section className="border-b border-[var(--color-border)] bg-[var(--color-card)]">
        <PageShell>
          <div className="py-16 sm:py-24">
            <p className="text-sm font-medium uppercase tracking-widest text-[var(--color-accent)]">
              Research · Code · Writing
            </p>
            <h1 className="mt-4 max-w-3xl text-4xl font-semibold tracking-tight sm:text-5xl">
              Economics, AI, and reproducible analysis — in one place.
            </h1>
            <p className="mt-6 max-w-2xl text-lg leading-8 text-[var(--color-muted)]">
              I build models and tools to understand how technology and policy shape welfare.
              This site collects projects, research notes, and occasional blog posts.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <ButtonLink href="/projects">View projects</ButtonLink>
              <ButtonLink href="/about">About me</ButtonLink>
            </div>
          </div>
        </PageShell>
      </section>

      <PageShell>
        <section className="py-12">
          <div className="mb-6 flex items-end justify-between gap-4">
            <h2 className="text-2xl font-semibold tracking-tight">Featured projects</h2>
            <Link href="/projects" className="text-sm text-[var(--color-accent)] hover:underline">
              See all
            </Link>
          </div>
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
        </section>

        <section className="py-12">
          <div className="mb-6 flex items-end justify-between gap-4">
            <h2 className="text-2xl font-semibold tracking-tight">Latest writing</h2>
            <Link href="/blog" className="text-sm text-[var(--color-accent)] hover:underline">
              See all
            </Link>
          </div>
          <div className="grid gap-6 md:grid-cols-2">
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
        </section>
      </PageShell>
    </>
  );
}
