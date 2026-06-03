import { MDXRemote, MDXRemoteProps } from "next-mdx-remote/rsc";

const components = {
  h2: (props: React.HTMLAttributes<HTMLHeadingElement>) => (
    <h2 className="mt-8 mb-3 text-2xl font-semibold tracking-tight" {...props} />
  ),
  h3: (props: React.HTMLAttributes<HTMLHeadingElement>) => (
    <h3 className="mt-6 mb-2 text-xl font-semibold tracking-tight" {...props} />
  ),
  p: (props: React.HTMLAttributes<HTMLParagraphElement>) => (
    <p className="mb-4 leading-7 text-[color-mix(in_oklab,var(--color-foreground)_88%,transparent)]" {...props} />
  ),
  ul: (props: React.HTMLAttributes<HTMLUListElement>) => (
    <ul className="mb-4 list-disc space-y-1 pl-6" {...props} />
  ),
  ol: (props: React.HTMLAttributes<HTMLOListElement>) => (
    <ol className="mb-4 list-decimal space-y-1 pl-6" {...props} />
  ),
  a: (props: React.AnchorHTMLAttributes<HTMLAnchorElement>) => (
    <a className="text-[var(--color-accent)] underline underline-offset-4" {...props} />
  ),
  code: (props: React.HTMLAttributes<HTMLElement>) => (
    <code
      className="rounded bg-[color-mix(in_oklab,var(--color-border)_50%,transparent)] px-1.5 py-0.5 font-mono text-sm"
      {...props}
    />
  ),
};

export function MdxContent(props: MDXRemoteProps) {
  return <MDXRemote {...props} components={components} />;
}
