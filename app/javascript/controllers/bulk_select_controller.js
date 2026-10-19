import { Controller } from "@hotwired/stimulus"

// Bulk approve/reject for the account review queue: "select all", plus two
// buttons that submit one form to different URLs. Native formmethod only does
// get/post, so the patch/delete method-override field is rewritten by hand.
// The form sits outside the table (each row has its own forms, and forms can't
// nest); row checkboxes join it through their HTML form attribute.
export default class extends Controller {
  static targets = [ "form", "selectAll", "row" ]
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

    this.formTarget.action = url
    this.formTarget.querySelector('input[name="_method"]').value = method
    this.formTarget.requestSubmit()
  }
}
