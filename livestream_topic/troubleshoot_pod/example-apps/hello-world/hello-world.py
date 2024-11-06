import sys
import time

def main():
    # Kiểm tra số lượng tham số
    if len(sys.argv) != 2:
        print("Error: Missing required argument.")
        print("Usage: python app.py <name>")
        sys.exit(1)

    name = sys.argv[1]
    print(f"Hello, {name}!")

    # Chạy sleep mãi mãi
    while True:
        time.sleep(60)  # Ngủ trong 60 giây mỗi lần, bạn có thể thay đổi nếu cần

if __name__ == "__main__":
    main()