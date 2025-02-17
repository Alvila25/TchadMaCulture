{% extends "base.html" %}
{% load static %}
{% block content %}

<!-- Navigation Bar -->
<nav class="navbar sticky">
    <div class="navbar-container">
        <a href="/" class="navbar-logo" aria-label="Home">TchadMaCulture</a>
        <ul class="navbar-links">
            <li><a href="#about">About</a></li>
            <li><a href="#heritage">Cultural Heritage</a></li>
            <li><a href="#events">Events</a></li>
            <li><a href="#meet-artisans">Meet the Artisans</a></li>
            <li><a href="#gallery">Gallery</a></li>
            <li><a href="#blog">Blog</a></li>
            <li><a href="#get-involved">Get Involved</a></li>
            <li><a href="#contact">Contact</a></li>
        </ul>
    </div>
</nav>

<header class="hero">
    <div class="hero-container">
        <h1>Celebrate and Preserve Chadian Culture</h1>
        <p>Explore Chad’s rich cultural heritage, engage with local traditions, and contribute to preserving our history.</p>
        <button class="button" aria-label="Join Us">Join Us</button>
    </div>
    <div class="hero-image">
        <img src="{% static 'images/tchad_culture.jpeg' %}" alt="Chadian cultural representation" class="responsive-img" loading="lazy">
    </div>
</header>

<section id="about" class="about">
    <h2>About TchadMaCulture</h2>
    <p>
        TchadMaCulture is dedicated to preserving, promoting, and celebrating Chad’s diverse cultural heritage.
        Through storytelling, art, music, and history, we strive to keep our traditions alive for future generations.
    </p>
</section>

<section id="heritage" class="heritage">
    <h2>Our Cultural Heritage</h2>
    <div class="heritage-grid">
        <div class="heritage-item">
            <img src="{% static 'images/music_dance.jpeg' %}" alt="Traditional Music and Dance" class="responsive-img" loading="lazy">
            <h3>Traditional Music & Dance</h3>
            <p>Experience the rhythms and dances that have been passed down for generations.</p>
        </div>
        <div class="heritage-item">
            <img src="{% static 'images/cuisine.jpeg' %}" alt="Chadian Cuisine" class="responsive-img" loading="lazy">
            <h3>Chadian Cuisine</h3>
            <p>Discover the flavors of Chad’s unique and diverse culinary traditions.</p>
        </div>
        <div class="heritage-item">
            <img src="{% static 'images/artifacts.jpeg' %}" alt="Historical Artifacts" class="responsive-img" loading="lazy">
            <h3>Historical Artifacts</h3>
            <p>Learn about the artifacts and ancient traditions that shape Chad’s history.</p>
        </div>
    </div>
</section>

<section id="events" class="events">
    <h2>Upcoming Cultural Events</h2>
    <p>Join us in celebrating Chad’s culture through various events, festivals, and workshops.</p>
    <div class="event-list" id="dynamic-events">
        <p>Loading events...</p>
    </div>
</section>

<section id="meet-artisans" class="meet-artisans">
    <h2>Meet the Artisans</h2>
    <p>Discover the talented artists, musicians, and craftsmen preserving Chad’s heritage.</p>
    <div class="artisan-list">
        <div class="artisan">
            <h3>Fatima Oumar</h3>
            <p>A renowned potter creating traditional Chadian ceramics.</p>
        </div>
        <div class="artisan">
            <h3>Moussa Abdoulaye</h3>
            <p>A master kora player sharing ancient melodies.</p>
        </div>
    </div>
</section>

<section id="gallery" class="gallery">
    <h2>Gallery</h2>
    <p>Explore visuals showcasing Chad’s vibrant culture.</p>
    <div class="gallery-grid">
        <img src="{% static 'images/gallery1.jpeg' %}" alt="Chadian festival" loading="lazy">
        <img src="{% static 'images/gallery2.jpeg' %}" alt="Traditional craftwork" loading="lazy">
    </div>
</section>

<section id="blog" class="blog">
    <h2>Stories & Insights</h2>
    <p>Read about Chadian cultural history, interviews, and personal experiences.</p>
    <div class="blog-list">
        <div class="blog-post">
            <h3>The Art of Chadian Weaving</h3>
            <p>A deep dive into the weaving traditions passed down through generations.</p>
        </div>
    </div>
</section>

<section id="newsletter" class="newsletter">
    <h2>Stay Updated</h2>
    <p>Subscribe to our newsletter to receive the latest updates on Chadian culture and events.</p>
    <input type="email" placeholder="Enter your email" aria-label="Email Address">
    <button class="button">Subscribe</button>
</section>

<section id="get-involved" class="get-involved">
    <h2>Get Involved</h2>
    <p>Join our mission to preserve Chad’s cultural heritage by volunteering, donating, or collaborating.</p>
    <button class="button">Become a Member</button>
</section>

<section id="testimonials" class="testimonials">
    <h2>What People Say</h2>
    <p>Hear from those passionate about Chadian culture.</p>
    <div class="testimonial">
        <blockquote>"TchadMaCulture has been an eye-opener to the rich traditions of Chad."</blockquote>
        <p>- Awa Mahamat</p>
    </div>
</section>

<footer id="contact">
    <div class="footer-content">
        <div class="contact-info">
            <h4>Contact Us</h4>
            <p>Email: info@tchadmaculture.com</p>
            <p>Phone: +235 6789 1234</p>
            <p>Address: N'Djamena, Chad</p>
        </div>
        <div class="social-media">
            <h4>Follow Us</h4>
            <p>
                <a href="#">Facebook</a> | <a href="#">Instagram</a> | <a href="#">Twitter</a>
            </p>
        </div>
    </div>
</footer>

<script defer>
    document.addEventListener("DOMContentLoaded", function() {
        document.getElementById("dynamic-events").innerHTML = `<div class='event'><h3>Chad Heritage Festival</h3><p>Date: December 5, 2024 | Location: Abeche</p><p>Join us for a grand celebration of Chad's history and traditions.</p></div>`;
    });
</script>

{% endblock %}
