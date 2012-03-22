function setCurrentLink() {
	var l = document.links;
	for (var i = 0; i < l.length; i++) {
		var a = l[i].href;
		var b = location.href;
		if (a.indexOf(b) != -1 || (b.charAt(b.length - 1) == "/" && a.indexOf("index.aspx") != -1)) {
			l[i].className = "current";
			break;
		}
	}
}
