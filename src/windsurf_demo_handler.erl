-module(windsurf_demo_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Html = <<"<!DOCTYPE html>
<html>
    <head>
        <meta charset=\"UTF-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
        <title>Windsurf Demo Chat</title>
        <style>
            :root {
                --color-primary: #10b981;
                --color-primary-dark: #059669;
                --color-primary-light: #d1fae5;
                --color-gray: #374151;
                --color-gray-light: #f3f4f6;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                margin: 0;
                padding: 10px;
                background: var(--color-gray-light);
                color: var(--color-gray);
                height: 100vh;
                display: flex;
                flex-direction: column;
            }

            .container {
                max-width: 600px;
                margin: 0 auto;
                width: 100%;
                background: white;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
                padding: 12px;
                flex-grow: 1;
                display: flex;
                flex-direction: column;
            }

            h1 {
                text-align: center;
                color: var(--color-primary-dark);
                margin: 0.5rem 0;
                font-size: 1.5rem;
                font-weight: 600;
            }

            #username-container {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                padding: 0.75rem;
                background: var(--color-primary-light);
                border-radius: 6px;
                margin-bottom: 0.75rem;
            }

            #messages {
                flex-grow: 1;
                overflow-y: auto;
                padding: 0.5rem;
                margin-bottom: 0.75rem;
                border: 1px solid #e5e7eb;
                border-radius: 6px;
                background: #ffffff;
            }

            #input-container {
                display: none;
                gap: 0.5rem;
                margin-top: auto;
            }

            input[type='text'] {
                flex-grow: 1;
                padding: 0.5rem 0.75rem;
                border: 1.5px solid #e5e7eb;
                border-radius: 4px;
                font-size: 0.875rem;
                transition: border-color 0.2s;
            }

            input[type='text']:focus {
                outline: none;
                border-color: var(--color-primary);
                box-shadow: 0 0 0 2px var(--color-primary-light);
            }

            button {
                padding: 0.5rem 1rem;
                background: var(--color-primary);
                color: white;
                border: none;
                border-radius: 4px;
                font-weight: 500;
                font-size: 0.875rem;
                cursor: pointer;
                transition: background-color 0.2s;
            }

            button:hover {
                background: var(--color-primary-dark);
            }

            .message {
                margin: 0.25rem 0;
                padding: 0.5rem 0.75rem;
                border-radius: 6px;
                max-width: 85%;
                word-wrap: break-word;
                font-size: 0.875rem;
            }

            .message.system {
                background: #f3f4f6;
                color: #6b7280;
                text-align: center;
                max-width: 100%;
                font-style: italic;
                font-size: 0.75rem;
                padding: 0.25rem 0.5rem;
                margin: 0.25rem 0;
            }

            .message.self {
                background: var(--color-primary);
                color: white;
                margin-left: auto;
                border-bottom-right-radius: 2px;
            }

            .message.other {
                background: var(--color-gray-light);
                color: var(--color-gray);
                margin-right: auto;
                border-bottom-left-radius: 2px;
            }

            .username {
                font-size: 0.75rem;
                margin-bottom: 0.125rem;
                font-weight: 600;
            }

            .message.self .username {
                color: rgba(255, 255, 255, 0.9);
            }

            .message.other .username {
                color: var(--color-primary-dark);
            }

            @media (max-width: 640px) {
                body {
                    padding: 8px;
                }

                .container {
                    border-radius: 6px;
                    padding: 8px;
                }

                .message {
                    max-width: 90%;
                }
            }
        </style>
    </head>
    <body>
        <div class=\"container\">
            <h1>Windsurf Chat</h1>
            <div id=\"username-container\">
                <input type=\"text\" id=\"username-input\" placeholder=\"Enter your username\" autofocus>
                <button onclick=\"setUsername()\">Join Chat</button>
            </div>
            <div id=\"messages\"></div>
            <div id=\"input-container\">
                <input type=\"text\" id=\"message-input\" placeholder=\"Type your message...\" onkeypress=\"if(event.key === 'Enter') sendMessage()\">
                <button onclick=\"sendMessage()\">Send</button>
            </div>
        </div>
        <script>
            let ws = null;
            let username = '';
            
            function setUsername() {
                const input = document.getElementById('username-input');
                const inputUsername = input.value.trim();
                if (inputUsername) {
                    username = inputUsername;
                    document.getElementById('username-container').style.display = 'none';
                    document.getElementById('input-container').style.display = 'flex';
                    connectWebSocket(username);
                } else {
                    alert('Please enter a username');
                }
            }
            
            function connectWebSocket(username) {
                const wsUrl = new URL('/ws', window.location.href);
                wsUrl.protocol = wsUrl.protocol.replace('http', 'ws');
                wsUrl.searchParams.append('username', username);
                console.log('Connecting with URL:', wsUrl.href);
                ws = new WebSocket(wsUrl.href);
                
                ws.onopen = function() {
                    console.log('Connected to WebSocket with username:', username);
                    addSystemMessage('Connected to chat as: ' + username);
                };
                
                ws.onclose = function() {
                    console.log('Disconnected from WebSocket');
                    addSystemMessage('Disconnected from chat');
                };
                
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    addMessage(data.message, data.username, username === data.username);
                };
            }
            
            function sendMessage() {
                const input = document.getElementById('message-input');
                const message = input.value.trim();
                if (message && ws && ws.readyState === WebSocket.OPEN) {
                    ws.send(message);
                    input.value = '';
                }
            }
            
            function addMessage(message, msgUsername, isSelf) {
                const messagesDiv = document.getElementById('messages');
                const messageDiv = document.createElement('div');
                messageDiv.className = `message ${isSelf ? 'self' : 'other'}`;
                
                const usernameDiv = document.createElement('div');
                usernameDiv.className = 'username';
                usernameDiv.textContent = msgUsername;
                
                const messageContent = document.createElement('div');
                messageContent.className = 'message-content';
                messageContent.textContent = message;
                
                messageDiv.appendChild(usernameDiv);
                messageDiv.appendChild(messageContent);
                messagesDiv.appendChild(messageDiv);
                messagesDiv.scrollTop = messagesDiv.scrollHeight;
            }
            
            function addSystemMessage(message) {
                const messagesDiv = document.getElementById('messages');
                const messageDiv = document.createElement('div');
                messageDiv.className = 'message system';
                messageDiv.textContent = message;
                messagesDiv.appendChild(messageDiv);
                messagesDiv.scrollTop = messagesDiv.scrollHeight;
            }

            document.getElementById('username-input').addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    setUsername();
                }
            });
        </script>
    </body>
</html>">>,
    {ok, cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/html">>},
        Html,
        Req0),
    State}.
