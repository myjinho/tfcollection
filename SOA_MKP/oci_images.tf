variable "marketplace_source_images" {
  type = map(object({
    ocid = string
    is_pricing_associated = bool
    compatible_shapes = set(string)
  }))
  default = {
    main_mktpl_image = {
      ocid = "ocid1.image.oc1..aaaaaaaasmj2pwqhtjv3uxkzs2o7ozxrkumyrhxfzimt6noxdblwuqx2beza"
      is_pricing_associated = false
      compatible_shapes = []
    }
  }
}