import Link from "next/link";
import { formatDate } from "@/lib/content";

type ContentCardProps = {
  href: string;
  title: string;
  date: string;
  summary: string;
  tags?: string[];
};

export function ContentCard({ href, title, date, summary, tags = [] }: ContentCardProps) {
  return (
    <article className="group rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 transition hover:border-[var(--color-accent)]/40">
      <Link href={href} className="block space-y-3">
        <div className="flex flex-wrap items-center gap-2 text-xs text-[var(--color-muted)]">
          <time dateTime={date}>{formatDate(date)}</time>
          {tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              className="rounded-full border border-[var(--color-border)] px-2 py-0.5"
            >
              {tag}
            </span>
          ))}
        </div>
        <h2 className="text-xl font-semibold tracking-tight group-hover:text-[var(--color-accent)]">
          {title}
        </h2>
        <p className="text-sm leading-6 text-[var(--color-muted)]">{summary}</p>
      </Link>
    </article>
  );
}
