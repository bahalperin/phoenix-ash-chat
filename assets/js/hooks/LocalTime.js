export const LocalTime = {
  mounted() {
    this.updated();
  },
  updated() {
    const el = this.el
    const date = new Date(el.dateTime);

    const now = new Date()
    const thisYear = now.getFullYear()

    const year = date.getFullYear()
    const month = date.toLocaleString('default', { month: 'long'})
    const day = date.getDate()
    const hours = date.getHours()
    const minutes = date.getMinutes()

    const displayDate = year  === thisYear
      ? `${month} ${day}`
      : `${month} ${day}, ${year}`

    const displayHours = hours % 12
    const isAM = hours <= 12
    this.el.textContent = [
      displayDate,
      'at',
      `${displayHours}:${minutes}`,
      isAM ? 'AM' : 'PM'
    ].join(' ')
  },
};