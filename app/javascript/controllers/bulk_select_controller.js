import { Controller } from "@hotwired/stimulus"

// Drives the account review queue's bulk approve/reject form: a "select all"
// checkbox that toggles every row, and two buttons that submit the same form
// to different URLs with different HTTP methods (native formmethod only
// supports get/post, so Rails' patch/delete method-override hidden field has
// to be rewritten by hand before submitting).
export default class extends Controller {
  static targets = [ "selectAll", "row" ]
  static values = { approveUrl: String, rejectUrl: String }

  toggleAll() {
    this.rowTargets.forEach((checkbox) => {
      checkbox.checked = this.selectAllTarget.checked
    })
  }

  approve() {
    this.submitBulkAction(
      this.approveUrlValue,
      "patch",
      "Approve all selected accounts and notify them by email?"
    )
  }

  reject() {
    this.submitBulkAction(
      this.rejectUrlValue,
      "delete",
      "Reject and delete all selected accounts? They will not be notified."
    )
  }

  submitBulkAction(url, method, confirmMessage) {
    if (!this.rowTargets.some((checkbox) => checkbox.checked)) {
      alert("No accounts were selected.")
      return
    }

    if (!window.confirm(confirmMessage)) return

    this.element.action = url
    this.element.querySelector('input[name="_method"]').value = method
    this.element.requestSubmit()
  }
}
