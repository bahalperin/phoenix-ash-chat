export const Message = {
  mounted() {
    const createdAt = this.el.dataset.createdAt
    const userId = this.el.dataset.userId
    const senderId = this.el.dataset.senderId

    if (senderId !== userId) {
      return
    }

    if (Date.now() - new Date(createdAt).getTime() > 1000) {
      return
    }

    this.el.scrollIntoView()
  },
};