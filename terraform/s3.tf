# ==============================================================================
# S3 Media Bucket (Raw Uploads & Transcoded Video Chunks)
# ==============================================================================

resource "aws_s3_bucket" "media" {
  bucket = var.media_bucket_name

  tags = {
    Name = var.media_bucket_name
  }
}

import {
  to = aws_s3_bucket.media
  id = "yellowbird-media-amaan"
}

# ==============================================================================
# CORS Configuration (Allows Browser Video Streaming)
# ==============================================================================

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

import {
  to = aws_s3_bucket_cors_configuration.media
  id = "yellowbird-media-amaan"
}