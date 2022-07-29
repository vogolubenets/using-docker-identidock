from flask import Flask, Response, request
import requests
import hashlib
import redis
import html


app = Flask(__name__)

SALT = "unique_salt"
DEFAULT_NAME = "Вячеслав Голубенец"

redis_cache = redis.StrictRedis(host="redis", port=6379, db=0)


@app.route("/", methods=["GET", "POST"])
def main_page():
    name = DEFAULT_NAME

    if request.method == "POST":
        name = html.escape(request.form["name"], quote=True)

    salted_name = SALT + name
    name_hash = hashlib.sha256(salted_name.encode()).hexdigest()

    header = "<html><head><title>Identidock</title></head>"
    body = """
        <body>
            <form method="POST">
                Hello <input type="text" name="name" value="{0}">
                <input type="submit" value="submit">
            </form>
            <p>
                You look like a:
                <img src="/monster/{1}"/>
            </p>
        </body>
    """.format(name, name_hash)
    footer = "</html>"

    return header + body + footer


@app.route("/monster/<name>")
def get_identicon(name):
    image = redis_cache.get(name)
    if image is None:
        print(f"Redis cache missed for name={name}")
        r = requests.get(f"http://dnmonster:8080/monster/{name}?size=80")
        image = r.content
        redis_cache.set(name, image)

    return Response(image, mimetype="image/png")


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
