"""
CV Website - Flask Backend API
Cloud Computing Final Project
"""

import os
import json
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory
from google.cloud import firestore
from google.cloud import storage

# Initialize Flask app
app = Flask(__name__, static_folder='static')

# Initialize GCP clients
PROJECT_ID = os.environ.get('GCP_PROJECT', 'projectrb-1')
STORAGE_BUCKET = os.environ.get('STORAGE_BUCKET', f'{PROJECT_ID}-cv-assets')

db = firestore.Client(project=PROJECT_ID)
storage_client = storage.Client(project=PROJECT_ID)


# Root route - Serve the CV website
@app.route('/')
def index():
    """Serve the main CV page"""
    return send_from_directory('static', 'index.html')


# Serve static files
@app.route('/static/<path:path>')
def serve_static(path):
    """Serve static files (CSS, JS, images)"""
    return send_from_directory('static', path)


# API: Get CV data
@app.route('/api/cv-data', methods=['GET'])
def get_cv_data():
    """Return CV data from JSON file"""
    try:
        with open('data/cv_data.json', 'r') as f:
            cv_data = json.load(f)
        return jsonify(cv_data), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# API: Submit contact form
@app.route('/api/contact', methods=['POST'])
def submit_contact():
    """Save contact form submission to Firestore"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'message']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create contact document
        contact_data = {
            'name': data['name'],
            'email': data['email'],
            'subject': data.get('subject', 'No subject'),
            'message': data['message'],
            'timestamp': firestore.SERVER_TIMESTAMP,
            'ip_address': request.remote_addr,
            'user_agent': request.headers.get('User-Agent', 'Unknown')
        }
        
        # Save to Firestore
        doc_ref = db.collection('contacts').add(contact_data)
        
        return jsonify({
            'success': True,
            'message': 'Thank you for your message! I will get back to you soon.',
            'id': doc_ref[1].id
        }), 201
        
    except Exception as e:
        app.logger.error(f'Error saving contact: {str(e)}')
        return jsonify({'error': 'Failed to submit contact form'}), 500


# API: Track analytics (page views, visitor data)
@app.route('/api/analytics', methods=['POST'])
def track_analytics():
    """Track visitor analytics"""
    try:
        data = request.get_json()
        
        analytics_data = {
            'page': data.get('page', '/'),
            'timestamp': firestore.SERVER_TIMESTAMP,
            'ip_address': request.remote_addr,
            'user_agent': request.headers.get('User-Agent', 'Unknown'),
            'referrer': data.get('referrer', ''),
            'screen_width': data.get('screen_width'),
            'screen_height': data.get('screen_height')
        }
        
        # Save to Firestore
        db.collection('analytics').add(analytics_data)
        
        return jsonify({'success': True}), 201
        
    except Exception as e:
        app.logger.error(f'Error tracking analytics: {str(e)}')
        return jsonify({'error': 'Failed to track analytics'}), 500


# API: Get visitor statistics (optional admin view)
@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get visitor statistics"""
    try:
        # Get total contacts
        contacts_ref = db.collection('contacts')
        contacts_count = len(list(contacts_ref.stream()))
        
        # Get total page views
        analytics_ref = db.collection('analytics')
        analytics_count = len(list(analytics_ref.stream()))
        
        # Get recent contacts (last 10)
        recent_contacts = []
        for doc in contacts_ref.order_by('timestamp', direction=firestore.Query.DESCENDING).limit(10).stream():
            contact = doc.to_dict()
            # Remove sensitive data
            recent_contacts.append({
                'name': contact.get('name'),
                'subject': contact.get('subject'),
                'timestamp': contact.get('timestamp')
            })
        
        stats = {
            'total_contacts': contacts_count,
            'total_page_views': analytics_count,
            'recent_contacts': recent_contacts
        }
        
        return jsonify(stats), 200
        
    except Exception as e:
        app.logger.error(f'Error getting stats: {str(e)}')
        return jsonify({'error': 'Failed to get statistics'}), 500


# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for Cloud Run"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()}), 200


# Error handlers
@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors"""
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors"""
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    # For local development
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=True)

