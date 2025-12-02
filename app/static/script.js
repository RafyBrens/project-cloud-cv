/**
 * CV Website - JavaScript
 * Handles dynamic content loading, form submission, and analytics
 */

// State
let cvData = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    loadCVData();
    setupContactForm();
    trackPageView();
    setCurrentYear();
});

/**
 * Load CV data from API
 */
async function loadCVData() {
    try {
        const response = await fetch('/api/cv-data');
        if (!response.ok) throw new Error('Failed to load CV data');
        
        cvData = await response.json();
        populatePage();
    } catch (error) {
        console.error('Error loading CV data:', error);
        showError('Failed to load CV data. Please refresh the page.');
    }
}

/**
 * Populate page with CV data
 */
function populatePage() {
    if (!cvData) return;
    
    // Update hero section
    updateElement('nav-name', cvData.name);
    updateElement('hero-name', cvData.name);
    updateElement('hero-title', cvData.title);
    updateElement('hero-email', cvData.email);
    updateElement('hero-phone', cvData.phone);
    updateElement('hero-location', cvData.location);
    updateElement('footer-name', cvData.name);
    
    // Update about section
    updateElement('about-summary', cvData.summary);
    
    // Update page title
    document.title = `CV - ${cvData.name}`;
    
    // Populate sections
    populateExperience();
    populateEducation();
    populateSkills();
    populateProjects();
}

/**
 * Helper function to update element text content
 */
function updateElement(id, content) {
    const element = document.getElementById(id);
    if (element && content) {
        element.textContent = content;
    }
}

/**
 * Populate experience section
 */
function populateExperience() {
    const container = document.getElementById('experience-list');
    if (!container || !cvData.experience) return;
    
    container.innerHTML = '';
    
    cvData.experience.forEach(exp => {
        const item = document.createElement('div');
        item.className = 'timeline-item';
        
        const responsibilities = Array.isArray(exp.responsibilities) 
            ? exp.responsibilities.map(r => `<li>${r}</li>`).join('')
            : `<p>${exp.responsibilities}</p>`;
        
        item.innerHTML = `
            <h3>${exp.position}</h3>
            <div class="timeline-meta">
                <span class="timeline-company">${exp.company}</span>
                <span class="separator">|</span>
                <span>${exp.duration}</span>
                ${exp.location ? `<span class="separator">|</span><span class="timeline-location">${exp.location}</span>` : ''}
            </div>
            <div class="timeline-description">
                ${Array.isArray(exp.responsibilities) ? '<ul>' + responsibilities + '</ul>' : responsibilities}
            </div>
        `;
        
        container.appendChild(item);
    });
}

/**
 * Populate education section
 */
function populateEducation() {
    const container = document.getElementById('education-list');
    if (!container || !cvData.education) return;
    
    container.innerHTML = '';
    
    cvData.education.forEach(edu => {
        const item = document.createElement('div');
        item.className = 'timeline-item';
        
        item.innerHTML = `
            <h3>${edu.degree}</h3>
            <div class="timeline-meta">
                <span class="timeline-company">${edu.institution}</span>
                <span class="separator">|</span>
                <span>${edu.duration}</span>
                ${edu.location ? `<span class="separator">|</span><span class="timeline-location">${edu.location}</span>` : ''}
            </div>
            ${edu.description ? `<div class="timeline-description"><p>${edu.description}</p></div>` : ''}
        `;
        
        container.appendChild(item);
    });
}

/**
 * Populate skills section
 */
function populateSkills() {
    const container = document.getElementById('skills-container');
    if (!container || !cvData.skills) return;
    
    container.innerHTML = '';
    
    cvData.skills.forEach(skillCategory => {
        const categoryDiv = document.createElement('div');
        categoryDiv.className = 'skill-category';
        
        const tags = skillCategory.items
            .map(skill => `<span class="skill-tag">${skill}</span>`)
            .join('');
        
        categoryDiv.innerHTML = `
            <h3>${skillCategory.category}</h3>
            <div class="skill-tags">${tags}</div>
        `;
        
        container.appendChild(categoryDiv);
    });
}

/**
 * Populate projects section
 */
function populateProjects() {
    const container = document.getElementById('projects-grid');
    if (!container || !cvData.projects) return;
    
    container.innerHTML = '';
    
    cvData.projects.forEach(project => {
        const card = document.createElement('div');
        card.className = 'project-card';
        
        card.innerHTML = `
            <div class="project-content">
                <h3>${project.name}</h3>
                <p class="project-tech">${project.technologies}</p>
                <p class="project-description">${project.description}</p>
            </div>
        `;
        
        container.appendChild(card);
    });
}

/**
 * Setup contact form
 */
function setupContactForm() {
    const form = document.getElementById('contact-form');
    if (!form) return;
    
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = {
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            subject: document.getElementById('subject').value || 'No subject',
            message: document.getElementById('message').value
        };
        
        try {
            const response = await fetch('/api/contact', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
            
            const result = await response.json();
            
            if (response.ok) {
                showFormStatus('success', result.message || 'Message sent successfully!');
                form.reset();
            } else {
                showFormStatus('error', result.error || 'Failed to send message. Please try again.');
            }
        } catch (error) {
            console.error('Error submitting form:', error);
            showFormStatus('error', 'Network error. Please try again later.');
        }
    });
}

/**
 * Show form status message
 */
function showFormStatus(type, message) {
    const statusDiv = document.getElementById('form-status');
    if (!statusDiv) return;
    
    statusDiv.className = `form-status ${type}`;
    statusDiv.textContent = message;
    
    // Hide after 5 seconds
    setTimeout(() => {
        statusDiv.className = 'form-status';
    }, 5000);
}

/**
 * Track page view analytics
 */
async function trackPageView() {
    try {
        await fetch('/api/analytics', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                page: window.location.pathname,
                referrer: document.referrer,
                screen_width: window.screen.width,
                screen_height: window.screen.height
            })
        });
    } catch (error) {
        console.error('Error tracking analytics:', error);
    }
}

/**
 * Download CV as PDF
 */
function downloadCV() {
    // Note: You would upload your actual CV PDF to Cloud Storage
    // and update this URL
    alert('CV download feature ready! Upload your CV PDF to Cloud Storage and update this function.');
    
    // Example implementation:
    // const pdfUrl = 'https://storage.googleapis.com/your-bucket/cv.pdf';
    // window.open(pdfUrl, '_blank');
}

/**
 * Set current year in footer
 */
function setCurrentYear() {
    const yearElement = document.getElementById('current-year');
    if (yearElement) {
        yearElement.textContent = new Date().getFullYear();
    }
}

/**
 * Show error message
 */
function showError(message) {
    console.error(message);
    alert(message);
}

/**
 * Smooth scroll to section
 */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

