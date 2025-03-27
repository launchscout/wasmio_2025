import publishMessage from 'publish-message';

export function addMessage(message) {
  publishMessage(message);
  publishMessage("And here is a message from a wasm component!!");
  return message;
}

export function init() {
  return ["You joined the wasm component chat!"];
}

export function messageAdded(message, messages) {
  return [...messages, message];
}
