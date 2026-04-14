variable "security_contact_email" {
  description = "Email for Defender for Cloud security alerts"
  type        = string
}

variable "enable_defender_paid" {
  description = "Enable paid Defender plans. Free tier if false."
  type        = bool
  default     = false
}
