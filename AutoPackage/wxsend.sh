#!/bin/zsh

BUILD_VERSION=$1
QRCODE_FILE_URL=$2

data=$(cat <<EOF
{
    "msgtype": "news",
    "news": {
        "articles" : [{
            "title" : "iOS测试包${BUILD_VERSION}打包完成",
            "description" : "这个版本修复了如下内容：\n 1、修复了流畅度 \n 2、修复了图片上传合法性 \n 3、修复版本号不能自增的bug",
            "url" : "${QRCODE_FILE_URL}",
            "picurl" : "${QRCODE_FILE_URL}"
        }]
    }
}
EOF
)
echo $data

curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=dd846600-1c0e-40b5-a124-cfb4a3952a5e' \
-H 'Content-Type: application/json' \
-d "$data"
