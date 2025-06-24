document.addEventListener('DOMContentLoaded', () => {
    // Smooth Scrolling for Navigation Links
    document.querySelectorAll('.nav-links a').forEach(anchor => {
        anchor.addEventListener('click', e => {
            e.preventDefault();
            const targetId = anchor.getAttribute('href').slice(1);
            const targetElement = document.getElementById(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });

    // Gallery Lightbox
    const galleryImages = document.querySelectorAll('.gallery img');
    const lightbox = document.createElement('div');
    lightbox.id = 'lightbox';
    Object.assign(lightbox.style, {
        display: 'none',
        position: 'fixed',
        top: '0',
        left: '0',
        width: '100%',
        height: '100%',
        background: 'rgba(0,0,0,0.8)',
        zIndex: '1001',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center'
    });
    const lightboxImg = document.createElement('img');
    Object.assign(lightboxImg.style, {
        maxWidth: '90%',
        maxHeight: '90%',
        borderRadius: '5px'
    });
    lightbox.appendChild(lightboxImg);
    document.body.appendChild(lightbox);

    galleryImages.forEach(img => {
        img.addEventListener('click', () => {
            lightboxImg.src = img.src;
            lightbox.style.display = 'flex';
        });
    });

    lightbox.addEventListener('click', e => {
        if (e.target === lightbox) {
            lightbox.style.display = 'none';
        }
    });

    // Contact Form Validation and Submission
    const contactForm = document.getElementById('contactForm');
    const formMessage = document.createElement('div');
    Object.assign(formMessage.style, {
        marginTop: '1rem',
        display: 'none',
        fontSize: '1rem'
    });
    contactForm.appendChild(formMessage);

    contactForm.addEventListener('submit', async e => {
        e.preventDefault();
        const name = document.getElementById('contact-name').value.trim();
        const email = document.getElementById('contact-email').value.trim();
        const message = document.getElementById('contact-message').value.trim();
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!name || name.length < 2) {
            formMessage.textContent = '{% trans "Please enter a valid name (minimum 2 characters)." %}';
            formMessage.style.color = '#e74c3c';
            formMessage.style.display = 'block';
            return;
        }
        if (!email || !emailRegex.test(email)) {
            formMessage.textContent = '{% trans "Please enter a valid email address." %}';
            formMessage.style.color = '#e74c3c';
            formMessage.style.display = 'block';
            return;
        }
        if (!message || message.length < 10) {
            formMessage.textContent = '{% trans "Please enter a message (minimum 10 characters)." %}';
            formMessage.style.color = '#e74c3c';
            formMessage.style.display = 'block';
            return;
        }

        try {
            const response = await fetch(contactForm.action, {
                method: 'POST',
                headers: { 'Accept': 'application/json' },
                body: new FormData(contactForm)
            });
            formMessage.style.display = 'block';
            if (response.ok) {
                formMessage.textContent = '{% trans "Message sent successfully! We’ll get back to you soon." %}';
                formMessage.style.color = '#2ecc71';
                contactForm.reset();
            } else {
                throw new Error('Submission failed');
            }
        } catch (error) {
            formMessage.textContent = '{% trans "Failed to send message. Please try again later." %}';
            formMessage.style.color = '#e74c3c';
            formMessage.style.display = 'block';
        }
    });

    // Enhanced Lazy Loading
    const lazyImages = document.querySelectorAll('img[loading="lazy"]');
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src || img.src;
                    img.classList.add('loaded');
                    observer.unobserve(img);
                }
            });
        }, { rootMargin: '100px' });
        lazyImages.forEach(img => imageObserver.observe(img));
    } else {
        lazyImages.forEach(img => {
            img.src = img.dataset.src || img.src;
            img.classList.add('loaded');
        });
    }

    // CSS for Lazy Loading Fade-In
    const style = document.createElement('style');
    style.textContent = `
        img[loading="lazy"] { opacity: 0; transition: opacity 0.5s ease-in; }
        img.loaded { opacity: 1; }
    `;
    document.head.appendChild(style);
});

// Interactive Map
function showInfo(region) {
    const regions = {
        'ndjamena': {
            title: '{% trans "N\'Djamena" %}',
            info: '{% trans "The capital city, a vibrant hub of Chadian culture and history." %}'
        },
        'lac': {
            title: '{% trans "Lac Region" %}',
            info: '{% trans "Home to Lake Chad, a vital cultural and economic landmark." %}'
        },
        'ennedi': {
            title: '{% trans "Ennedi" %}',
            info: '{% trans "Known for its stunning rock formations and ancient cave paintings." %}'
        }
    };
    const regionData = regions[region] || { title: '{% trans "Region Name" %}', info: '{% trans "Click on a region to explore its culture and traditions." %}' };
    document.getElementById('region-title').textContent = regionData.title;
    document.getElementById('region-info').textContent = regionData.info;
}

// Quiz
function checkAnswer() {
    const correctAnswers = { quiz1: 'B', quiz2: 'D', quiz3: 'C' };
    let score = 0;
    for (let i = 1; i <= 3; i++) {
        const selected = document.querySelector(`input[name="quiz${i}"]:checked`);
        if (selected && selected.value === correctAnswers[`quiz${i}`]) {
            score++;
        }
    }
    const result = document.getElementById('result');
    result.textContent = `{% trans "You got" %} ${score} {% trans "out of 3 correct!" %}`;
    document.getElementById('badge').style.display = score === 3 ? 'block' : 'none';
}