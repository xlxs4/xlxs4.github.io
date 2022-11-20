old_folder_structure = False
# This is a simple script using `css_html_js_minify` (available via pip) to compress html and css
# files (the js that we use is already compressed). This script takes negligible time to run.

import os
from css_html_js_minify import process_single_html_file as min_html
from css_html_js_minify import process_single_css_file as min_css
from multiprocessing import Pool, cpu_count
from functools import partial

# modify those if you're not using the standard output paths.
if old_folder_structure:
    CSS, PUB   = "css", "pub"
    html_files = ["index.html"]
    for root, dirs, files in os.walk(PUB):
        for fname in files:
            if fname.endswith(".html"):
                html_files.append(os.path.join(root, fname))

    css_files = []

    for root, dirs, files in os.walk(CSS):
        for fname in files:
            if fname.endswith(".css"):
                css_files.append(os.path.join(root, fname))
else:
    html_files = []
    css_files  = []
    for root, dirs, files in os.walk("__site"):
        for fname in files:
            if fname.endswith(".html"):
                html_files.append(os.path.join(root, fname))
            if fname.endswith(".css"):
                css_files.append(os.path.join(root, fname))

if os.name == 'nt':
    # multiprocessing doesn't seem to go well with windows...
    for file in html_files:
        min_html(file, overwrite=True)
    for file in css_files:
        min_css(file, overwrite=True)
else:
    pool = Pool(cpu_count())

    pool.map_async(partial(min_html, overwrite=True), html_files)
    pool.map_async(partial(min_css, overwrite=True), css_files)

    pool.close()
    pool.join()
