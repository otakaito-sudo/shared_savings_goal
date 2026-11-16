import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["total", "member", "summary"]

  connect() { this.update() }

  memberSum() {
    let sum = 0
    for (const input of this.memberTargets) {
      if (!input.validity.valid || input.value === "") return null
      sum += Number(input.value)
    }
    return Number.isSafeInteger(sum) ? sum : null
  }

  update() {
    const sum = this.memberSum()
    if (sum === null || !this.totalTarget.validity.valid || this.totalTarget.value === "") {
      this.summaryTarget.textContent = "金額を正しく入力してください。"
      return
    }
    const difference = Number(this.totalTarget.value) - sum
    const formattedSum = sum.toLocaleString("ja-JP")
    this.summaryTarget.textContent = difference === 0
      ? `個人目標の合計 ${formattedSum}円（一致しています）`
      : `個人目標の合計 ${formattedSum}円 ／ 全体目標との差額 ${difference.toLocaleString("ja-JP")}円`
  }

  applySum() {
    const sum = this.memberSum()
    if (sum === null) return
    this.totalTarget.value = sum
    this.update()
  }
}
