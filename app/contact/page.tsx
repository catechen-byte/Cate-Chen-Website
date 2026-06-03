import type { Metadata } from "next";
import { PageHeader, PageShell } from "@/components/page-shell";

export const metadata: Metadata = {
  title: "Contact",
  description: "Get in touch with Cate Chen.",
};

export default function ContactPage() {
  return (
    <>
      <PageHeader title="Contact" description="Reach out for collaborations, questions, or feedback." />
      <PageShell narrow>
        <div className="prose">
          <p>
            The fastest way to reach me is email. Replace the placeholder below with your address
            in <code>app/contact/page.tsx</code> or set up a form provider later.
          </p>
          <p>
            <a href="mailto:hello@example.com">catechen@college.harvard.edu</a>
          </p>
          <p>
            You can also find project code in this repository on GitHub once published.
          </p>
        </div>
      </PageShell>
    </>
  );
}
