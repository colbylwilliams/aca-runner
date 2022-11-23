import hmac
import logging
import os

from json import dumps
from sys import stderr

from azure.storage.queue import QueueClient
from flask import Flask, abort, request

logging.basicConfig(stream=stderr, level=logging.INFO)

application = Flask(__name__)

WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET')
STORAGE_CONNECTION_STRING = os.environ.get('STORAGE_CONNECTION_STRING')
STORAGE_QUEUE_NAME = os.environ.get('STORAGE_QUEUE_NAME')

queue_client = QueueClient.from_connection_string(STORAGE_CONNECTION_STRING, STORAGE_QUEUE_NAME)


def add_queue_message(msg):
    queue_client.send_message(msg)


def delete_message():
    msg = queue_client.receive_message()
    queue_client.delete_message(msg)


@application.route('/', methods=['GET', 'POST'])
def index():
    """
    Main WSGI application entry.
    """

    if request.method != 'POST':
        abort(501, "only POST is supported")

    # Enforce secret, so not just anybody can trigger these hooks
    if not WEBHOOK_SECRET:
        logging.warning('WEBHOOK_SECRET not set')
    else:
        # Validate the payload
        signature = request.headers.get('X-Hub-Signature')
        if not signature:
            abort(403, 'X-Hub-Signature missing from request')

        logging.info(f'X-Hub-Signature: {signature}')

        sha_name, signature = signature.split('=')
        if sha_name != 'sha1':
            abort(501, 'only sha1 is supported')

        logging.info(f'signature: {signature}')

        mac = hmac.new(WEBHOOK_SECRET.encode(), msg=request.data, digestmod='sha1')

        if not hmac.compare_digest(str(mac.hexdigest()), str(signature)):
            abort(403, 'X-Hub-Signature does not match blob signature')

    # Implement ping
    event = request.headers.get('X-GitHub-Event', 'ping')
    if event == 'ping':
        return dumps({'msg': 'pong'})

    # Gather data
    try:
        payload = request.get_json()
    except Exception:
        logging.warning('Request parsing failed')
        abort(400, "Request parsing failed")

    # Determining the branch can be tricky, as it only appears for certain event
    # types, and at different levels
    branch = None
    try:
        # Case 1: a ref_type indicates the type of ref.
        # This true for create and delete events.
        if 'ref_type' in payload:
            if payload['ref_type'] == 'branch':
                branch = payload['ref']

        # Case 2: a pull_request object is involved. This is pull_request and
        # pull_request_review_comment events.
        elif 'pull_request' in payload:
            # This is the TARGET branch for the pull-request, not the source
            # branch
            branch = payload['pull_request']['base']['ref']

        elif event in ['push']:
            # Push events provide a full Git ref in 'ref' and not a 'ref_type'.
            branch = payload['ref'].split('/', 2)[2]

    except KeyError:
        # If the payload structure isn't what we expect, we'll live without
        # the branch name
        pass

    # All current events have a repository, but some legacy events do not,
    # so let's be safe
    name = payload['repository']['name'] if 'repository' in payload else None
    meta = {
        'name': name,
        'branch': branch,
        'event': event
    }

    logging.info('Metadata:\n{}'.format(dumps(meta)))

    # Skip push-delete
    if event == 'push' and payload['deleted']:
        logging.info('Skipping push-delete event for {}'.format(dumps(meta)))
        return dumps({'status': 'skipped'})

    if event == 'workflow_job':

        action = payload['action'].lower()
        if action == 'queued':
            add_queue_message(payload['workflow_job']['run_id'])
        elif action == 'completed':
            delete_message()

        return dumps({'status': 'done'})

    return dumps({'status': 'nop'})


if __name__ == '__main__':
    application.run(debug=False, host='0.0.0.0', port=80)
