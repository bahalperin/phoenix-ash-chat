
export const MessageForm = {
  updated() {
    if (document.getElementsByClassName('invalid-feedback').length == 0) {
      const input = document.getElementById('message-input');
      input.value = '';
    }
  }
}