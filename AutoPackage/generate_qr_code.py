# generate_qr_code.py
import sys
import qrcode
import hashlib
import base64
from PIL import Image

def generate_qr_code_and_md5(url, save_path):
    # Create QRCode object
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    # Add data
    qr.add_data(url)
    qr.make(fit=True)

    # Create PIL image object
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(save_path)

    # 计算文件内容的 MD5 值
    md5 = hashlib.md5()
    with open(save_path, "rb") as f:
        while True:
            chunk = f.read(8192)  # 以块的方式读取文件内容
            if not chunk:
                break
            md5.update(chunk)
            
    # 获取文件内容的 MD5 值的十六进制表示
    md5_value = md5.hexdigest()

    # 读取图像数据并转换为 Base64 编码
    with open(save_path, "rb") as f:
        image_data = f.read()
        base64_image = base64.b64encode(image_data).decode('utf-8')
    
    return base64_image, md5_value

if __name__ == "__main__":
    # Get URL and save path from command line arguments
    if len(sys.argv) < 3:
        print("Usage: python generate_qr_code.py <URL> <Save Path>")
        sys.exit(1)
    
    url = sys.argv[1]
    path = sys.argv[2]
    base64_image, md5_value = generate_qr_code_and_md5(url, path)
#    print("Base64 Image:", base64_image)
#    print("MD5:", md5_value)

