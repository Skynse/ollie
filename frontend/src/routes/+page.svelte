<script lang="ts">
    import { onMount } from "svelte";

    let isVisible = false;

    onMount(() => {
        isVisible = true;
    });
</script>

<svelte:head>
    <title>Ollie - Local-first Kanban Board</title>
    <meta
        name="description"
        content="A local-first kanban board with sprints, time tracking and burndown. Your work stays on your device."
    />
    <link rel="icon" type="image/png" href="/images/icon.png" />
</svelte:head>

<div class="landing">
    <!-- Hero Section -->
    <section class="hero" class:visible={isVisible}>
        <div class="hero-background">
            <img
                src="/images/board.png"
                alt="Ollie Kanban Board"
                class="hero-bg-image"
            />
            <div class="hero-overlay"></div>
        </div>
        <div class="container">
            <div class="hero-content">
                <div class="glass-card">
                    <div class="brand-logo">
                        <img src="/images/icon.png" alt="Ollie" />
                        <h2>Ollie</h2>
                    </div>
                    <h1 class="hero-title">
                        Your workflow,<br />
                        <span class="highlight-text">on your device</span>
                    </h1>
                    <p class="hero-subtitle">
                        Ollie is a focused, local-first kanban board with
                        sprints, time tracking and burndown charts. No account,
                        no server — your work stays on your device.
                    </p>
                    <div class="hero-cta">
                        <a
                            href="https://app.ollieboard.dev"
                            class="btn btn-primary"
                        >
                            Launch App
                        </a>
                        <a href="#features" class="btn btn-secondary">
                            Learn More
                        </a>
                    </div>
                    <p class="hero-note">This product is in beta.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Screenshots Section -->
    <section class="screenshots">
        <div class="container">
            <h2 class="section-title">See Ollie in action</h2>
            <p class="section-subtitle">
                Everything you need to manage your work
            </p>

            <div class="screenshots-grid">
                <div class="screenshot-card">
                    <img src="/images/dash.png" alt="Sprint Dashboard" />
                    <h3>Project Dashboard</h3>
                    <p>
                        Create and manage multiple boards, columns and cards
                        from one clean home screen.
                    </p>
                </div>
                <div class="screenshot-card">
                    <img src="/images/board.png" alt="Kanban Board" />
                    <h3>Kanban Board</h3>
                    <p>Drag and drop tasks with instant local updates</p>
                </div>
                <div class="screenshot-card">
                    <img src="/images/burndown.png" alt="Burndown Chart" />
                    <h3>Analytics</h3>
                    <p>Visualize sprint velocity and health</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features">
        <div class="container">
            <h2 class="section-title">Everything you need</h2>
            <p class="section-subtitle">Built for focused, local work</p>

            <div class="features-grid">
                <div class="feature-card">
                    <div class="feature-icon">🎯</div>
                    <h3>Kanban Boards</h3>
                    <p>
                        Drag-and-drop task management with customizable columns
                        and priorities.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">⏱️</div>
                    <h3>Time Tracking</h3>
                    <p>
                        Log time against cards, edit entries, and keep card
                        totals in sync.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">⚡</div>
                    <h3>Sprint Management</h3>
                    <p>
                        Plan, track, and review sprints with built-in velocity
                        charts.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">🔒</div>
                    <h3>Private by Default</h3>
                    <p>
                        Boards live in a local SQLite database on your device.
                        No account and no server.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">🚀</div>
                    <h3>Lightning Fast</h3>
                    <p>
                        Built with Flutter and local SQLite for instant updates.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">📱</div>
                    <h3>Works Everywhere</h3>
                    <p>
                        Web, mobile, and desktop. One codebase, every platform.
                    </p>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta">
        <div class="container">
            <div class="cta-content">
                <h2>Ready to simplify your workflow?</h2>
                <p>Everything stays on your device</p>
                <a
                    href="https://app.ollieboard.dev"
                    class="btn btn-primary btn-large"
                >
                    Launch App
                </a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-content">
                <div class="footer-brand">
                    <div class="footer-logo">
                        <img src="/images/icon.png" alt="Ollie" />
                        <h3>Ollie</h3>
                    </div>
                    <p>Local-first kanban for focused work</p>
                </div>
                <div class="footer-links">
                    <div class="footer-column">
                        <h4>Product</h4>
                        <a href="https://app.ollieboard.dev">Launch App</a>
                        <a href="#features">Features</a>
                    </div>
                    <div class="footer-column">
                        <h4>Company</h4>
                        <a href="mailto:popshuvitapps@gmail.com">Contact</a>
                    </div>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2025 Popshuvit. All rights reserved.</p>
            </div>
        </div>
    </footer>
</div>

<style>
    :global(*) {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    :global(body) {
        font-family:
            -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
            Ubuntu, sans-serif;
        color: #1a1a1a;
        background: #ffffff;
        line-height: 1.6;
    }

    .landing {
        overflow-x: hidden;
    }

    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 2rem;
    }

    /* Hero Section */
    .hero {
        min-height: 100vh;
        display: flex;
        align-items: center;
        padding: 4rem 0;
        position: relative;
        opacity: 0;
        transform: translateY(20px);
        transition:
            opacity 0.8s ease,
            transform 0.8s ease;
        overflow: hidden;
    }

    .hero.visible {
        opacity: 1;
        transform: translateY(0);
    }

    .hero-background {
        position: absolute;
        inset: 0;
        z-index: 0;
    }

    .hero-bg-image {
        width: 100%;
        height: 100%;
        object-fit: cover;
        filter: blur(8px) brightness(0.7);
    }

    .hero-overlay {
        position: absolute;
        inset: 0;
        background: rgba(0, 0, 0, 0.6);
    }

    .hero .container {
        position: relative;
        z-index: 1;
        display: flex;
        justify-content: center;
        align-items: center;
    }

    .hero-content {
        max-width: 800px;
        width: 100%;
    }

    /* Glassmorphism Card */
    .glass-card {
        background: rgba(255, 255, 255, 0.15);
        backdrop-filter: blur(20px);
        -webkit-backdrop-filter: blur(20px);
        border: 1px solid rgba(255, 255, 255, 0.2);
        border-radius: 24px;
        padding: 3rem;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    /* Brand Logo */
    .brand-logo {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .brand-logo img {
        width: 64px;
        height: 64px;
        border-radius: 12px;
    }

    .brand-logo h2 {
        font-size: 2rem;
        font-weight: 700;
        color: white;
        margin: 0;
    }

    .hero-title {
        font-size: 3.5rem;
        font-weight: 700;
        line-height: 1.1;
        margin-bottom: 1.5rem;
        letter-spacing: -0.02em;
        color: white;
    }

    .highlight-text {
        color: #3b82f6;
    }

    .hero-subtitle {
        font-size: 1.25rem;
        color: rgba(255, 255, 255, 0.9);
        margin-bottom: 2rem;
        line-height: 1.6;
    }

    .hero-cta {
        display: flex;
        gap: 1rem;
        margin-bottom: 1rem;
    }

    .hero-note {
        color: rgba(255, 255, 255, 0.7);
        font-size: 0.9rem;
    }

    /* Buttons */
    .btn {
        display: inline-block;
        padding: 0.875rem 2rem;
        border-radius: 12px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s ease;
        font-size: 1rem;
        border: none;
        cursor: pointer;
    }

    .btn-primary {
        background: #3b82f6;
        color: white;
        box-shadow: 0 4px 15px rgba(59, 130, 246, 0.3);
    }

    .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(59, 130, 246, 0.4);
    }

    .btn-secondary {
        background: white;
        color: #3b82f6;
        border: 2px solid #3b82f6;
    }

    .btn-secondary:hover {
        background: #f7f8ff;
    }

    .btn-large {
        padding: 1.125rem 2.5rem;
        font-size: 1.125rem;
    }

    /* Screenshots Section */
    .screenshots {
        padding: 6rem 0;
        background: white;
    }

    .screenshots-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
        gap: 3rem;
    }

    .screenshot-card {
        text-align: center;
    }

    .screenshot-card img {
        width: 100%;
        height: auto;
        border-radius: 16px;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        margin-bottom: 1.5rem;
        transition:
            transform 0.3s ease,
            box-shadow 0.3s ease;
    }

    .screenshot-card img:hover {
        transform: translateY(-8px);
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
    }

    .screenshot-card h3 {
        font-size: 1.5rem;
        margin-bottom: 0.75rem;
        font-weight: 600;
    }

    .screenshot-card p {
        color: #666;
        line-height: 1.6;
        max-width: 400px;
        margin: 0 auto;
    }

    /* Features Section */
    .features {
        padding: 6rem 0;
        background: #f8f9fa;
    }

    .section-title {
        text-align: center;
        font-size: 2.5rem;
        font-weight: 700;
        margin-bottom: 0.5rem;
    }

    .section-subtitle {
        text-align: center;
        color: #666;
        font-size: 1.25rem;
        margin-bottom: 4rem;
    }

    .features-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 2rem;
    }

    .feature-card {
        background: white;
        padding: 2rem;
        border-radius: 16px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
        transition:
            transform 0.2s ease,
            box-shadow 0.2s ease;
    }

    .feature-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    }

    .feature-icon {
        font-size: 2.5rem;
        margin-bottom: 1rem;
    }

    .feature-card h3 {
        font-size: 1.5rem;
        margin-bottom: 0.75rem;
        font-weight: 600;
    }

    .feature-card p {
        color: #666;
        line-height: 1.6;
    }

    /* CTA Section */
    .cta {
        padding: 6rem 0;
        background: #3b82f6;
        color: white;
    }

    .cta-content {
        text-align: center;
    }

    .cta h2 {
        font-size: 2.5rem;
        margin-bottom: 1rem;
        font-weight: 700;
    }

    .cta p {
        font-size: 1.25rem;
        margin-bottom: 2rem;
        opacity: 0.9;
    }

    .cta .btn-primary {
        background: white;
        color: #3b82f6;
    }

    .cta .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 30px rgba(255, 255, 255, 0.3);
    }

    /* Footer */
    .footer {
        padding: 4rem 0 2rem;
        background: #1a1a1a;
        color: white;
    }

    .footer-content {
        display: grid;
        grid-template-columns: 2fr 1fr;
        gap: 4rem;
        margin-bottom: 3rem;
    }

    .footer-logo {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 0.5rem;
    }

    .footer-logo img {
        width: 40px;
        height: 40px;
        border-radius: 8px;
    }

    .footer-brand h3 {
        font-size: 1.5rem;
        margin: 0;
    }

    .footer-brand p {
        color: #999;
    }

    .footer-links {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 2rem;
    }

    .footer-column h4 {
        margin-bottom: 1rem;
        font-size: 1rem;
        font-weight: 600;
    }

    .footer-column a {
        display: block;
        color: #999;
        text-decoration: none;
        margin-bottom: 0.5rem;
        transition: color 0.2s ease;
    }

    .footer-column a:hover {
        color: white;
    }

    .footer-bottom {
        padding-top: 2rem;
        border-top: 1px solid #333;
        text-align: center;
        color: #666;
        font-size: 0.9rem;
    }

    /* Responsive */
    @media (max-width: 768px) {
        .hero .container {
            grid-template-columns: 1fr;
            gap: 3rem;
        }

        .hero-title {
            font-size: 2.5rem;
        }

        .hero-cta {
            flex-direction: column;
        }

        .features-grid {
            grid-template-columns: 1fr;
        }

        .footer-content {
            grid-template-columns: 1fr;
            gap: 2rem;
        }

        .section-title {
            font-size: 2rem;
        }

        .cta h2 {
            font-size: 2rem;
        }
    }
</style>
