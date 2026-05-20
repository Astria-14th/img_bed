import os
from PIL import Image, ImageFilter

def add_black_border(input_path, border_width=2):
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    alpha = img.split()[3]
    
    edge = alpha.filter(ImageFilter.FIND_EDGES)
    
    border = Image.new("L", (width, height), 0)
    
    for x in range(width):
        for y in range(height):
            if edge.getpixel((x, y)) > 0:
                for dx in range(-border_width, border_width + 1):
                    for dy in range(-border_width, border_width + 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < width and 0 <= ny < height:
                            border.putpixel((nx, ny), 255)
    
    result = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    result.paste((0, 0, 0, 255), mask=border)
    
    result.paste(img, (0, 0), img)
    
    result.save(input_path)
    print(f"处理完成: {input_path}")

def process_folder(folder_path):
    png_count = 0
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.lower().endswith('.png'):
                input_path = os.path.join(root, file)
                add_black_border(input_path)
                png_count += 1
    
    print(f"\n全部处理完成！共处理 {png_count} 个 PNG 文件")

if __name__ == "__main__":
    clothes_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "clothes")
    process_folder(clothes_folder)