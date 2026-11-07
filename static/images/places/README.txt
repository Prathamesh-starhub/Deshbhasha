Put place photos in this folder.
File name = the image_slug of the place + .jpg / .jpeg / .png / .webp
Example: ajanta-ellora-caves.jpg
Run  python check_images.py  to see which files are still missing (and to rebuild IMAGE_CHECKLIST.md).
Only use photos you took, or that are licensed for reuse (e.g. Wikimedia Commons, Unsplash).
Record the credit with:  UPDATE places SET image_credit='Name / licence' WHERE image_slug='ajanta-ellora-caves';
