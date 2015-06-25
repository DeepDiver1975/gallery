/* global OC, OCA, FileList, $, t */
var GalleryButton = {};
GalleryButton.isPublic = false;
GalleryButton.button = {};
GalleryButton.url = null;

GalleryButton.onFileListUpdated = function () {
	var fileList;

	if (GalleryButton.isPublic) {
		fileList = OCA.Sharing.PublicApp.fileList;
	} else {
		fileList = FileList;
	}

	GalleryButton.buildGalleryUrl(fileList.getCurrentDirectory().replace(/^\//, ''));
};

GalleryButton.buildGalleryUrl = function (dir) {
	var params = {};
	var tokenPath = '';
	var token = ($('#sharingToken').val()) ? $('#sharingToken').val() : false;
	if (token) {
		params.token = token;
		tokenPath = 's/{token}';
	}
	GalleryButton.url = OC.generateUrl('apps/galleryplus/' + tokenPath, params) + '#' + encodeURIComponent(dir);
};

$(document).ready(function () {

		if ($('#body-login').length > 0) {
			return true; //deactivate on login page
		}

		if ($('#isPublic').val()) {
			GalleryButton.isPublic = true;
		}

		if ($('#filesApp').val()) {

			$('#fileList').on('updated', GalleryButton.onFileListUpdated);

			// toggle for opening the files list in the Gallery app
			GalleryButton.button =
				$('<div class="button view-switcher left-switch-button disabled-button">' +
					'<img class="svg" src="' + OC.imagePath('core', 'actions/toggle-filelist.svg') +
					'"' +
					'alt="' + t('gallery', 'Picture view') + '"/>' +
					'</div>' +
					'<div id="gallery-button" class="button view-switcher right-switch-button inactive-button">' +
					'<img class="svg" src="' + OC.imagePath('core', 'actions/toggle-pictures.svg') +
					'"' +
					'alt="' + t('gallery', 'Picture view') + '"/>' +
					'</div>');

			GalleryButton.button.click(function () {
				$(this).addClass('loading');
				window.location.href = GalleryButton.url;
			});

			$('#controls').prepend(GalleryButton.button);
		}
	}
);
