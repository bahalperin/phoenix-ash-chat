
export const MessageForm = {
  mounted() {
    this.el.addEventListener('submit', () => {
      setTimeout(() => {
        document.getElementById('message-input').value = ''
      }, 50)
    })
  }
}