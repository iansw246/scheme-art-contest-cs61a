import subprocess
import os

def make_merge_images_command(base_file: str, overlay_file: str, output_file: str):
    return ["magick", "composite", base_file, "-compose", "Screen", "-gravity", "center", overlay_file, output_file]

def combine_images(image_count: int, output_dir: str):
    """
    Merges images in output_dir with file names output{i}.png, where i is index from [0, image_count)
    Returns path to file of merged output
    """
    base_file = os.path.join(output_dir, "output0.png")
    overlay_file = os.path.join(output_dir, "output1.png")
    output_file = os.path.join(output_dir, "merge.png")
    
    merge_command = ["magick", "composite", base_file, "-compose", "Screen", "-gravity", "center", overlay_file, output_file]
    subprocess.run(merge_command)
    base_file = output_file
    for i in range(2, image_count):
        overlay_file = os.path.join(output_dir, f"output{i}.png")
        merge_command = make_merge_images_command(base_file, overlay_file, output_file)
        subprocess.run(merge_command)
    return output_file
    
if __name__ == "__main__":
    import sys
    image_count = int(sys.argv[1])
    output_dir = sys.argv[2]
    combine_images(image_count, output_dir)