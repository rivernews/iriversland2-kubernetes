terraform {
    backend "pg" {
        schema_name = "public"
    }
}