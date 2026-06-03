import Link from "next/link";

type PageHeaderProps = {
  title: string;
  description?: string;
};

export function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <div className="mx-auto max-w-5xl px-6 pb-8 pt-12">
      <h1 className="text-4xl font-semibold tracking-tight">{title}</h1>
      {description ? (
        <p className="mt-4 max-w-2xl text-lg leading-8 text-[var(--color-muted)]">{description}</p>
      ) : null}
    </div>
  );
}

export function PageShell({
  children,
  narrow = false,
}: {
  children: React.ReactNode;
  narrow?: boolean;
}) {
  return (
    <div className={`mx-auto px-6 pb-16 ${narrow ? "max-w-3xl" : "max-w-5xl"}`}>{children}</div>
  );
}

export function ButtonLink({
  href,
  children,
  external = false,
}: {
  href: string;
  children: React.ReactNode;
  external?: boolean;
}) {
  const className =
    "inline-flex items-center rounded-lg bg-[var(--color-accent)] px-4 py-2 text-sm font-medium text-white transition hover:opacity-90";

  if (external) {
    return (
      <a href={href} target="_blank" rel="noreferrer" className={className}>
        {children}
      </a>
    );
  }

  return (
    <Link href={href} className={className}>
      {children}
    </Link>
  );
}
