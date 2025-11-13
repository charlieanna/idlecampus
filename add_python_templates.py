#!/usr/bin/env python3
"""
Script to add Python templates to remaining problem definition files.
This script reads each file, extracts userFacingFRs, and generates a naive Python implementation.
"""

import re
import os

# Directory containing the problem definition files
DEFINITIONS_DIR = "/Users/ankurkothari/Documents/workspace/idlecampus/frontend/src/apps/system-design/builder/challenges/definitions"

# Files to process
FILES_TO_PROCESS = [
    "bookingcom.ts",
    "messenger.ts",
    "medium.ts",
    "pastebin.ts",
    "pinterest.ts",
    "snapchat.ts",
    "stackoverflow.ts",
    "steam.ts",
    "telegram.ts",
    "ticketmaster.ts",
    "twitch.ts",
    "yelp.ts",
    "googlecalendar.ts",
    "googledrive.ts",
    "hulu.ts",
]

# Template generators for common patterns
def generate_booking_platform_template():
    return `from datetime import datetime
from typing import List, Dict

# In-memory storage (naive implementation)
users = {}
listings = {}
bookings = {}
payments = {}

def search_listings(location: str, check_in: str, check_out: str) -> List[Dict]:
    """
    Search for available listings
    Naive implementation - returns all listings
    """
    return list(listings.values())

def create_booking(booking_id: str, listing_id: str, user_id: str, check_in: str, check_out: str) -> Dict:
    """
    Create a booking
    Naive implementation - stores booking in memory
    """
    bookings[booking_id] = {
        'id': booking_id,
        'listing_id': listing_id,
        'user_id': user_id,
        'check_in': check_in,
        'check_out': check_out,
        'status': 'confirmed',
        'created_at': datetime.now()
    }
    return bookings[booking_id]

def process_payment(payment_id: str, booking_id: str, amount: float) -> Dict:
    """
    Process payment
    Naive implementation - stores payment record
    """
    payments[payment_id] = {
        'id': payment_id,
        'booking_id': booking_id,
        'amount': amount,
        'status': 'completed',
        'created_at': datetime.now()
    }
    return payments[payment_id]
`

def generate_messenger_template():
    return `from datetime import datetime
from typing import List, Dict

# In-memory storage (naive implementation)
users = {}
conversations = {}
messages = {}

def send_message(message_id: str, sender_id: str, recipient_id: str, content: str) -> Dict:
    """
    Send a message
    Naive implementation - stores message in memory
    """
    messages[message_id] = {
        'id': message_id,
        'sender_id': sender_id,
        'recipient_id': recipient_id,
        'content': content,
        'created_at': datetime.now()
    }
    return messages[message_id]

def get_conversation(user1_id: str, user2_id: str) -> List[Dict]:
    """
    Get conversation between two users
    Naive implementation - returns all messages between users
    """
    conversation = []
    for msg in messages.values():
        if (msg['sender_id'] == user1_id and msg['recipient_id'] == user2_id) or \
           (msg['sender_id'] == user2_id and msg['recipient_id'] == user1_id):
            conversation.append(msg)
    conversation.sort(key=lambda x: x['created_at'])
    return conversation
`

def extract_frs(content):
    """Extract userFacingFRs from file content."""
    match = re.search(r'userFacingFRs:\s*\[(.*?)\]', content, re.DOTALL)
    if match:
        frs_text = match.group(1)
        # Extract individual FRs
        frs = re.findall(r"'([^']*)'", frs_text)
        return frs
    return []

def has_python_template(content):
    """Check if file already has pythonTemplate."""
    return 'pythonTemplate' in content

def add_template_to_file(filepath, template):
    """Add Python template to a TypeScript file."""
    with open(filepath, 'r') as f:
        content = f.read()

    if has_python_template(content):
        print(f"Skipping {os.path.basename(filepath)} - already has template")
        return False

    # Find the validators section and add template before the closing brace
    pattern = r'(validators: \[.*?\],\s*\})(;)'
    replacement = r'\1,\n\n  pythonTemplate: `' + template + r'`,\n};'

    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    if new_content == content:
        print(f"Warning: Could not find validators section in {os.path.basename(filepath)}")
        return False

    with open(filepath, 'w') as f:
        f.write(new_content)

    print(f"Added template to {os.path.basename(filepath)}")
    return True

# Main execution would go here, but we'll handle this manually
print("Template generation script ready")
print(f"Files to process: {len(FILES_TO_PROCESS)}")
