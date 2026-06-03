import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { MdxContent } from "@/components/mdx-content";
import { ButtonLink, PageShell } from "@/components/page-shell";
import { formatDate, getAllContent, getContentBySlug } from "@/lib/content";

type Props = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  return getAllContent("research").map((item) => ({ slug: item.slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const item = getContentBySlug("research", slug);
  if (!item) return {};
  return { title: item.title, description: item.summary };
}

export default async function ResearchDetailPage({ params }: Props) {
  const { slug } = await params;
  const item = getContentBySlug("research", slug);
  if (!item) notFound();

  return (
    <PageShell narrow>
      <article className="py-12">
        <p className="text-sm text-[var(--color-muted)]">{formatDate(item.date)}</p>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight">{item.title}</h1>
        {item.citation ? (
          <p className="mt-4 text-sm italic text-[var(--color-muted)]">{item.citation}</p>
        ) : null}
        {item.abstract ? (
          <p className="mt-4 rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] p-4 text-[var(--color-muted)]">
            {item.abstract}
          </p>
        ) : null}
        {item.pdf ? (
          <div className="mt-6">
            <ButtonLink href={item.pdf} external>
              Download PDF
            </ButtonLink>
          </div>
        ) : null}
        <div className="prose mt-10">
          <MdxContent source={item.content} />
        </div>
      </article>
    </PageShell>
  );
}
