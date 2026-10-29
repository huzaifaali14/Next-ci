const features = [
  { title: "Fast", body: "Server-rendered pages with static assets cached at the edge." },
  { title: "Simple", body: "One container, one port, zero external dependencies." },
  { title: "Ready", body: "Health check endpoint at /api/health for load balancers." },
];

export default function Home() {
  return (
    <main className="home">
      <section className="hero">
        <span className="badge">Demo</span>
        <h1>Welcome to Acme Demo</h1>
        <p>This is a placeholder home page for the production deployment.</p>
      </section>
      <section className="grid">
        {features.map((f) => (
          <article key={f.title} className="card">
            <h2>{f.title}</h2>
            <p>{f.body}</p>
          </article>
        ))}
      </section>
      <footer>© 2026 Acme Demo</footer>
    </main>
  );
}
