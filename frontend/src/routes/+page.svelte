<script lang="ts">
    import { onMount } from "svelte";

    let isVisible = false;

    onMount(() => {
        isVisible = true;
    });
</script>

<svelte:head>
    <title>Ollie - Your Team's Kanban Board</title>
    <meta
        name="description"
        content="Simple, collaborative kanban boards for agile teams. Real-time updates, multiplayer cursors, and sprint management."
    />
</svelte:head>

<div class="landing">
    <!-- Hero Section -->
    <section class="hero" class:visible={isVisible}>
        <div class="container">
            <div class="hero-content">
                <h1 class="hero-title">
                    Team collaboration,<br />
                    <span class="gradient-text">simplified</span>
                </h1>
                <p class="hero-subtitle">
                    Ollie brings your team together with real-time kanban
                    boards, multiplayer cursors, and sprint tracking. Built for
                    modern agile teams.
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
                <p class="hero-note">
                    A Popshuvit product • Free for internal teams
                </p>
            </div>
            <div class="hero-visual">
                <div class="screenshot-container">
                    <img
                        src="/images/board.png"
                        alt="Ollie Kanban Board"
                        class="screenshot"
                    />
                    <div class="screenshot-glow"></div>
                </div>
            </div>
        </div>
    </section>

    <!-- Screenshots Section -->
    <section class="screenshots">
        <div class="container">
            <h2 class="section-title">See Ollie in action</h2>
            <p class="section-subtitle">
                Everything you need to manage your team's work
            </p>

            <div class="screenshots-grid">
                <div class="screenshot-card">
                    <img src="/images/dash.png" alt="Sprint Dashboard" />
                    <h3>Project Dashboard</h3>
                    <p>
                        Create and manage multiple boards, and invite team
                        members to collaborate on projects.
                    </p>
                </div>
                <div class="screenshot-card">
                    <img src="/images/board.png" alt="Kanban Board" />
                    <h3>Kanban Board</h3>
                    <p>Drag and drop tasks with real-time collaboration</p>
                </div>
                <div class="screenshot-card">
                    <img src="/images/burndown.png" alt="Burndown Chart" />
                    <h3>Analytics</h3>
                    <p>Visualize team velocity and sprint health</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features">
        <div class="container">
            <h2 class="section-title">Everything you need</h2>
            <p class="section-subtitle">Built for teams that ship fast</p>

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
                    <div class="feature-icon">👥</div>
                    <h3>Real-time Collaboration</h3>
                    <p>
                        See your teammates' cursors in real-time. Know who's
                        working on what.
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
                    <h3>Secure & Private</h3>
                    <p>
                        Your data is encrypted and stored securely. GDPR
                        compliant.
                    </p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">🚀</div>
                    <h3>Lightning Fast</h3>
                    <p>
                        Built with Flutter and WebSockets for instant updates.
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
                <p>Join teams using Ollie to ship faster</p>
                <a
                    href="https://app.ollieboard.dev"
                    class="btn btn-primary btn-large"
                >
                    Get Started Free
                </a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-content">
                <div class="footer-brand">
                    <h3>Ollie</h3>
                    <p>Simple kanban boards for agile teams</p>
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

    /* Hero Screenshot */
    .screenshot-container {
        position: relative;
        border-radius: 24px;
        overflow: hidden;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
    }

    .screenshot {
        width: 100%;
        height: auto;
        display: block;
        border-radius: 24px;
    }

    .screenshot-glow {
        position: absolute;
        inset: 0;
        background: linear-gradient(
            135deg,
            rgba(59, 130, 246, 0.2) 0%,
            rgba(236, 72, 153, 0.2) 100%
        );
        pointer-events: none;
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
    }

    .hero.visible {
        opacity: 1;
        transform: translateY(0);
    }

    .hero .container {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 4rem;
        align-items: center;
    }

    .hero-content {
        max-width: 600px;
    }

    .hero-title {
        font-size: 3.5rem;
        font-weight: 700;
        line-height: 1.1;
        margin-bottom: 1.5rem;
        letter-spacing: -0.02em;
    }

    .gradient-text {
        background: linear-gradient(135deg, #3b82f6 0%, #ec4899 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
    }

    .hero-subtitle {
        font-size: 1.25rem;
        color: #666;
        margin-bottom: 2rem;
        line-height: 1.6;
    }

    .hero-cta {
        display: flex;
        gap: 1rem;
        margin-bottom: 1rem;
    }

    .hero-note {
        color: #999;
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
        background: linear-gradient(135deg, #3b82f6 0%, #ec4899 100%);
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

    /* Board Preview Animation */
    .hero-visual {
        position: relative;
    }

    .board-preview {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1.5rem;
        padding: 2rem;
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        border-radius: 24px;
        position: relative;
    }

    .board-card {
        background: white;
        border-radius: 12px;
        padding: 1rem;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
        animation: slideUp 0.6s ease forwards;
        animation-delay: var(--delay);
        opacity: 0;
    }

    @keyframes slideUp {
        to {
            opacity: 1;
            transform: translateY(0);
        }
        from {
            opacity: 0;
            transform: translateY(20px);
        }
    }

    .card-header {
        height: 12px;
        background: linear-gradient(90deg, #3b82f6 0%, #ec4899 100%);
        border-radius: 6px;
        margin-bottom: 0.75rem;
    }

    .card-line {
        height: 8px;
        background: #e9ecef;
        border-radius: 4px;
        margin-bottom: 0.5rem;
    }

    .card-line.short {
        width: 60%;
    }

    .cursor {
        position: absolute;
        width: 16px;
        height: 16px;
        border-radius: 50%;
        animation: float 3s ease-in-out infinite;
    }

    .cursor-1 {
        background: #3b82f6;
        top: 30%;
        left: 20%;
        animation-delay: 0s;
    }

    .cursor-2 {
        background: #ec4899;
        bottom: 40%;
        right: 25%;
        animation-delay: 1.5s;
    }

    @keyframes float {
        0%,
        100% {
            transform: translate(0, 0);
        }
        50% {
            transform: translate(10px, -10px);
        }
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
        background: linear-gradient(135deg, #3b82f6 0%, #ec4899 100%);
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

    .footer-brand h3 {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
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

        .hero-visual {
            order: -1;
        }

        .hero-title {
            font-size: 2.5rem;
        }

        .hero-cta {
            flex-direction: column;
        }

        .board-preview {
            grid-template-columns: 1fr;
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
