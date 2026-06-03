export function SiteFooter() {
  return (
    <footer className="border-t border-[var(--color-border)]">
      <div className="mx-auto flex max-w-5xl flex-col gap-2 px-6 py-8 text-sm text-[var(--color-muted)] sm:flex-row sm:items-center sm:justify-between">
        <p>© {new Date().getFullYear()} Cate Chen</p>
        <p>Built with Next.js · deployed on Vercel</p>
      </div>
    </footer>
  );
}
