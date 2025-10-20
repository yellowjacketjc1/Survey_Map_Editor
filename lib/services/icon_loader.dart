import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/annotation_models.dart';
import '../models/posting_model.dart';

class IconLoader {
  static List<IconMetadata> loadMaterialIcons() {
    final icons = <IconMetadata>[];

    // Comprehensive list of Material Design icons
    final iconMap = {
      // Warning & Safety
      'warning': {'icon': Icons.warning, 'tags': ['warning', 'alert', 'caution']},
      'dangerous': {'icon': Icons.dangerous, 'tags': ['danger', 'hazard', 'warning']},
      'warning_amber': {'icon': Icons.warning_amber, 'tags': ['warning', 'amber', 'caution']},
      'error': {'icon': Icons.error, 'tags': ['error', 'problem', 'issue']},
      'error_outline': {'icon': Icons.error_outline, 'tags': ['error', 'outline', 'problem']},
      'report_problem': {'icon': Icons.report_problem, 'tags': ['report', 'problem', 'warning']},

      // Science & Lab
      'science': {'icon': Icons.science, 'tags': ['science', 'lab', 'equipment']},
      'biotech': {'icon': Icons.biotech, 'tags': ['biotech', 'biology', 'science']},

      // Measurement & Sensors
      'thermostat': {'icon': Icons.thermostat, 'tags': ['temperature', 'sensor']},
      'speed': {'icon': Icons.speed, 'tags': ['meter', 'gauge', 'measurement']},
      'timeline': {'icon': Icons.timeline, 'tags': ['timeline', 'graph', 'data']},
      'show_chart': {'icon': Icons.show_chart, 'tags': ['chart', 'graph', 'data']},
      'bar_chart': {'icon': Icons.bar_chart, 'tags': ['bar', 'chart', 'graph']},
      'pie_chart': {'icon': Icons.pie_chart, 'tags': ['pie', 'chart', 'graph']},
      'analytics': {'icon': Icons.analytics, 'tags': ['analytics', 'data', 'chart']},

      // Locations & Markers
      'location_on': {'icon': Icons.location_on, 'tags': ['location', 'marker', 'pin']},
      'location_off': {'icon': Icons.location_off, 'tags': ['location', 'off', 'disabled']},
      'place': {'icon': Icons.place, 'tags': ['place', 'location', 'marker']},
      'pin_drop': {'icon': Icons.pin_drop, 'tags': ['pin', 'drop', 'location']},
      'push_pin': {'icon': Icons.push_pin, 'tags': ['push', 'pin', 'marker']},
      'room': {'icon': Icons.room, 'tags': ['room', 'location', 'place']},
      'map': {'icon': Icons.map, 'tags': ['map', 'navigation', 'location']},
      'terrain': {'icon': Icons.terrain, 'tags': ['terrain', 'map', 'landscape']},
      'explore': {'icon': Icons.explore, 'tags': ['explore', 'compass', 'navigation']},

      // People & Workers
      'person': {'icon': Icons.person, 'tags': ['person', 'worker', 'human']},
      'person_add': {'icon': Icons.person_add, 'tags': ['person', 'add', 'new']},
      'person_remove': {'icon': Icons.person_remove, 'tags': ['person', 'remove', 'delete']},
      'groups': {'icon': Icons.groups, 'tags': ['people', 'group', 'workers']},
      'people': {'icon': Icons.people, 'tags': ['people', 'group', 'users']},
      'people_outline': {'icon': Icons.people_outline, 'tags': ['people', 'outline', 'group']},
      'engineering': {'icon': Icons.engineering, 'tags': ['engineering', 'worker', 'construction']},
      'admin_panel_settings': {'icon': Icons.admin_panel_settings, 'tags': ['admin', 'panel', 'settings']},
      'supervisor_account': {'icon': Icons.supervisor_account, 'tags': ['supervisor', 'account', 'admin']},

      // Construction & Tools
      'construction': {'icon': Icons.construction, 'tags': ['construction', 'work', 'tools']},
      'build': {'icon': Icons.build, 'tags': ['build', 'tools', 'wrench']},
      'build_circle': {'icon': Icons.build_circle, 'tags': ['build', 'circle', 'tools']},
      'handyman': {'icon': Icons.handyman, 'tags': ['handyman', 'tools', 'repair']},
      'hardware': {'icon': Icons.hardware, 'tags': ['hardware', 'tools', 'equipment']},
      'plumbing': {'icon': Icons.plumbing, 'tags': ['plumbing', 'pipe', 'tools']},
      'electrical_services': {'icon': Icons.electrical_services, 'tags': ['electrical', 'services', 'power']},
      'architecture': {'icon': Icons.architecture, 'tags': ['architecture', 'design', 'building']},
      'carpenter': {'icon': Icons.carpenter, 'tags': ['carpenter', 'wood', 'tools']},

      // Actions
      'delete': {'icon': Icons.delete, 'tags': ['delete', 'trash', 'remove']},
      'delete_forever': {'icon': Icons.delete_forever, 'tags': ['delete', 'forever', 'permanent']},
      'delete_outline': {'icon': Icons.delete_outline, 'tags': ['delete', 'outline', 'trash']},
      'block': {'icon': Icons.block, 'tags': ['block', 'forbidden', 'restricted']},
      'cancel': {'icon': Icons.cancel, 'tags': ['cancel', 'close', 'stop']},
      'check_circle': {'icon': Icons.check_circle, 'tags': ['check', 'approved', 'ok']},
      'check_circle_outline': {'icon': Icons.check_circle_outline, 'tags': ['check', 'outline', 'ok']},
      'do_not_disturb': {'icon': Icons.do_not_disturb, 'tags': ['do not disturb', 'no', 'stop']},
      'not_interested': {'icon': Icons.not_interested, 'tags': ['not interested', 'no', 'forbidden']},
      'undo': {'icon': Icons.undo, 'tags': ['undo', 'reverse', 'back']},
      'redo': {'icon': Icons.redo, 'tags': ['redo', 'forward', 'repeat']},

      // Information
      'info': {'icon': Icons.info, 'tags': ['info', 'information', 'help']},
      'info_outline': {'icon': Icons.info_outline, 'tags': ['info', 'outline', 'information']},
      'help': {'icon': Icons.help, 'tags': ['help', 'question', 'support']},
      'help_outline': {'icon': Icons.help_outline, 'tags': ['help', 'outline', 'question']},
      'help_center': {'icon': Icons.help_center, 'tags': ['help', 'center', 'support']},
      'report': {'icon': Icons.report, 'tags': ['report', 'document', 'flag']},
      'announcement': {'icon': Icons.announcement, 'tags': ['announcement', 'megaphone', 'alert']},

      // Media & Documentation
      'camera_alt': {'icon': Icons.camera_alt, 'tags': ['camera', 'photo', 'picture']},
      'photo_camera': {'icon': Icons.photo_camera, 'tags': ['photo', 'camera', 'picture']},
      'videocam': {'icon': Icons.videocam, 'tags': ['video', 'camera', 'record']},
      'mic': {'icon': Icons.mic, 'tags': ['microphone', 'audio', 'record']},
      'note': {'icon': Icons.note, 'tags': ['note', 'document', 'text']},
      'note_add': {'icon': Icons.note_add, 'tags': ['note', 'add', 'new']},
      'description': {'icon': Icons.description, 'tags': ['description', 'document', 'file']},
      'assignment': {'icon': Icons.assignment, 'tags': ['assignment', 'task', 'document']},
      'library_books': {'icon': Icons.library_books, 'tags': ['library', 'books', 'documents']},
      'book': {'icon': Icons.book, 'tags': ['book', 'reading', 'manual']},
      'article': {'icon': Icons.article, 'tags': ['article', 'document', 'text']},

      // Time & Date
      'calendar_today': {'icon': Icons.calendar_today, 'tags': ['calendar', 'date', 'schedule']},
      'calendar_month': {'icon': Icons.calendar_month, 'tags': ['calendar', 'month', 'date']},
      'event': {'icon': Icons.event, 'tags': ['event', 'calendar', 'date']},
      'access_time': {'icon': Icons.access_time, 'tags': ['time', 'clock', 'schedule']},
      'schedule': {'icon': Icons.schedule, 'tags': ['schedule', 'time', 'clock']},
      'timer': {'icon': Icons.timer, 'tags': ['timer', 'time', 'stopwatch']},
      'alarm': {'icon': Icons.alarm, 'tags': ['alarm', 'clock', 'time']},
      'watch_later': {'icon': Icons.watch_later, 'tags': ['watch', 'later', 'time']},

      // Arrows & Directions
      'arrow_forward': {'icon': Icons.arrow_forward, 'tags': ['arrow', 'forward', 'next']},
      'arrow_back': {'icon': Icons.arrow_back, 'tags': ['arrow', 'back', 'previous']},
      'arrow_upward': {'icon': Icons.arrow_upward, 'tags': ['arrow', 'up', 'upward']},
      'arrow_downward': {'icon': Icons.arrow_downward, 'tags': ['arrow', 'down', 'downward']},
      'arrow_left': {'icon': Icons.arrow_left, 'tags': ['arrow', 'left', 'back']},
      'arrow_right': {'icon': Icons.arrow_right, 'tags': ['arrow', 'right', 'forward']},
      'arrow_drop_down': {'icon': Icons.arrow_drop_down, 'tags': ['arrow', 'drop', 'down']},
      'arrow_drop_up': {'icon': Icons.arrow_drop_up, 'tags': ['arrow', 'drop', 'up']},
      'north': {'icon': Icons.north, 'tags': ['north', 'up', 'arrow']},
      'south': {'icon': Icons.south, 'tags': ['south', 'down', 'arrow']},
      'east': {'icon': Icons.east, 'tags': ['east', 'right', 'arrow']},
      'west': {'icon': Icons.west, 'tags': ['west', 'left', 'arrow']},
      'north_east': {'icon': Icons.north_east, 'tags': ['north', 'east', 'arrow']},
      'north_west': {'icon': Icons.north_west, 'tags': ['north', 'west', 'arrow']},
      'south_east': {'icon': Icons.south_east, 'tags': ['south', 'east', 'arrow']},
      'south_west': {'icon': Icons.south_west, 'tags': ['south', 'west', 'arrow']},
      'navigation': {'icon': Icons.navigation, 'tags': ['navigation', 'direction', 'compass']},
      'near_me': {'icon': Icons.near_me, 'tags': ['near', 'me', 'location']},
      'directions': {'icon': Icons.directions, 'tags': ['directions', 'navigation', 'route']},
      'directions_walk': {'icon': Icons.directions_walk, 'tags': ['walk', 'pedestrian', 'foot']},
      'directions_run': {'icon': Icons.directions_run, 'tags': ['run', 'running', 'person']},
      'directions_car': {'icon': Icons.directions_car, 'tags': ['car', 'vehicle', 'drive']},
      'turn_left': {'icon': Icons.turn_left, 'tags': ['turn', 'left', 'arrow']},
      'turn_right': {'icon': Icons.turn_right, 'tags': ['turn', 'right', 'arrow']},
      'u_turn_left': {'icon': Icons.u_turn_left, 'tags': ['u-turn', 'left', 'arrow']},
      'u_turn_right': {'icon': Icons.u_turn_right, 'tags': ['u-turn', 'right', 'arrow']},

      // Environment & Weather
      'water_drop': {'icon': Icons.water_drop, 'tags': ['water', 'liquid', 'drop']},
      'water': {'icon': Icons.water, 'tags': ['water', 'liquid', 'wave']},
      'local_fire_department': {'icon': Icons.local_fire_department, 'tags': ['fire', 'emergency']},
      'whatshot': {'icon': Icons.whatshot, 'tags': ['fire', 'flame', 'hot']},
      'cloud': {'icon': Icons.cloud, 'tags': ['cloud', 'weather', 'atmosphere']},
      'wb_sunny': {'icon': Icons.wb_sunny, 'tags': ['sunny', 'sun', 'weather']},
      'ac_unit': {'icon': Icons.ac_unit, 'tags': ['snow', 'cold', 'winter']},
      'opacity': {'icon': Icons.opacity, 'tags': ['water', 'drop', 'liquid']},
      'waves': {'icon': Icons.waves, 'tags': ['waves', 'water', 'radiation']},
      'air': {'icon': Icons.air, 'tags': ['air', 'wind', 'atmosphere']},
      'bolt': {'icon': Icons.bolt, 'tags': ['bolt', 'lightning', 'electric']},
      'flash_on': {'icon': Icons.flash_on, 'tags': ['flash', 'lightning', 'quick']},
      'power': {'icon': Icons.power, 'tags': ['power', 'energy', 'electric']},
      'energy_savings_leaf': {'icon': Icons.energy_savings_leaf, 'tags': ['energy', 'savings', 'eco']},
      'eco': {'icon': Icons.eco, 'tags': ['eco', 'environment', 'green']},
      'nature': {'icon': Icons.nature, 'tags': ['nature', 'tree', 'plant']},
      'nature_people': {'icon': Icons.nature_people, 'tags': ['nature', 'people', 'eco']},
      'park': {'icon': Icons.park, 'tags': ['park', 'trees', 'nature']},
      'forest': {'icon': Icons.forest, 'tags': ['forest', 'trees', 'nature']},

      // Shapes & Symbols
      'circle': {'icon': Icons.circle, 'tags': ['circle', 'shape', 'round']},
      'square': {'icon': Icons.square, 'tags': ['square', 'shape', 'box']},
      'rectangle': {'icon': Icons.rectangle, 'tags': ['rectangle', 'shape', 'box']},
      'star': {'icon': Icons.star, 'tags': ['star', 'favorite', 'important']},
      'star_border': {'icon': Icons.star_border, 'tags': ['star', 'border', 'outline']},
      'star_half': {'icon': Icons.star_half, 'tags': ['star', 'half', 'rating']},
      'flag': {'icon': Icons.flag, 'tags': ['flag', 'marker', 'report']},
      'outlined_flag': {'icon': Icons.outlined_flag, 'tags': ['flag', 'outlined', 'marker']},
      'label': {'icon': Icons.label, 'tags': ['label', 'tag', 'category']},
      'label_important': {'icon': Icons.label_important, 'tags': ['label', 'important', 'tag']},
      'sell': {'icon': Icons.sell, 'tags': ['sell', 'tag', 'price']},
      'change_history': {'icon': Icons.change_history, 'tags': ['triangle', 'shape', 'change']},

      // Equipment & Objects
      'local_hospital': {'icon': Icons.local_hospital, 'tags': ['hospital', 'medical', 'health']},
      'medical_services': {'icon': Icons.medical_services, 'tags': ['medical', 'health', 'services']},
      'medication': {'icon': Icons.medication, 'tags': ['medication', 'pill', 'medicine']},
      'vaccines': {'icon': Icons.vaccines, 'tags': ['vaccine', 'medical', 'injection']},
      'masks': {'icon': Icons.masks, 'tags': ['mask', 'ppe', 'protection']},
      'security': {'icon': Icons.security, 'tags': ['security', 'shield', 'protection']},
      'shield': {'icon': Icons.shield, 'tags': ['shield', 'protection', 'security']},
      'verified_user': {'icon': Icons.verified_user, 'tags': ['verified', 'user', 'secure']},
      'lock': {'icon': Icons.lock, 'tags': ['lock', 'secure', 'restricted']},
      'lock_open': {'icon': Icons.lock_open, 'tags': ['lock', 'open', 'unlocked']},
      'key': {'icon': Icons.key, 'tags': ['key', 'unlock', 'access']},
      'vpn_key': {'icon': Icons.vpn_key, 'tags': ['key', 'password', 'access']},
      'visibility': {'icon': Icons.visibility, 'tags': ['visibility', 'eye', 'view']},
      'visibility_off': {'icon': Icons.visibility_off, 'tags': ['visibility off', 'hidden', 'eye']},
      'lightbulb': {'icon': Icons.lightbulb, 'tags': ['lightbulb', 'idea', 'light']},
      'flashlight_on': {'icon': Icons.flashlight_on, 'tags': ['flashlight', 'on', 'light']},
      'flashlight_off': {'icon': Icons.flashlight_off, 'tags': ['flashlight', 'off', 'dark']},

      // Transportation & Vehicles
      'local_shipping': {'icon': Icons.local_shipping, 'tags': ['shipping', 'truck', 'delivery']},
      'fire_truck': {'icon': Icons.fire_truck, 'tags': ['fire', 'truck', 'emergency']},
      'emergency': {'icon': Icons.emergency, 'tags': ['emergency', 'alert', 'urgent']},
      'airport_shuttle': {'icon': Icons.airport_shuttle, 'tags': ['airport', 'shuttle', 'bus']},
      'commute': {'icon': Icons.commute, 'tags': ['commute', 'travel', 'transport']},
      'traffic': {'icon': Icons.traffic, 'tags': ['traffic', 'light', 'signal']},
      'railway_alert': {'icon': Icons.railway_alert, 'tags': ['railway', 'alert', 'train']},

      // Basic Actions
      'add': {'icon': Icons.add, 'tags': ['add', 'plus', 'new']},
      'add_circle': {'icon': Icons.add_circle, 'tags': ['add', 'circle', 'plus']},
      'add_circle_outline': {'icon': Icons.add_circle_outline, 'tags': ['add', 'outline', 'plus']},
      'add_box': {'icon': Icons.add_box, 'tags': ['add', 'box', 'plus']},
      'remove': {'icon': Icons.remove, 'tags': ['remove', 'minus', 'subtract']},
      'remove_circle': {'icon': Icons.remove_circle, 'tags': ['remove', 'circle', 'minus']},
      'remove_circle_outline': {'icon': Icons.remove_circle_outline, 'tags': ['remove', 'outline', 'minus']},
      'edit': {'icon': Icons.edit, 'tags': ['edit', 'modify', 'change']},
      'create': {'icon': Icons.create, 'tags': ['create', 'new', 'edit']},
      'save': {'icon': Icons.save, 'tags': ['save', 'store', 'disk']},
      'save_alt': {'icon': Icons.save_alt, 'tags': ['save', 'download', 'alt']},
      'close': {'icon': Icons.close, 'tags': ['close', 'cancel', 'exit']},
      'clear': {'icon': Icons.clear, 'tags': ['clear', 'remove', 'close']},
      'check': {'icon': Icons.check, 'tags': ['check', 'ok', 'confirm']},
      'done': {'icon': Icons.done, 'tags': ['done', 'complete', 'finished']},
      'done_all': {'icon': Icons.done_all, 'tags': ['done', 'all', 'complete']},
      'copy': {'icon': Icons.copy, 'tags': ['copy', 'duplicate', 'clone']},
      'content_copy': {'icon': Icons.content_copy, 'tags': ['copy', 'content', 'duplicate']},
      'content_cut': {'icon': Icons.content_cut, 'tags': ['cut', 'scissors', 'trim']},
      'content_paste': {'icon': Icons.content_paste, 'tags': ['paste', 'clipboard', 'insert']},

      // UI Elements
      'settings': {'icon': Icons.settings, 'tags': ['settings', 'config', 'gear']},
      'settings_applications': {'icon': Icons.settings_applications, 'tags': ['settings', 'applications', 'config']},
      'tune': {'icon': Icons.tune, 'tags': ['tune', 'adjust', 'settings']},
      'home': {'icon': Icons.home, 'tags': ['home', 'house', 'main']},
      'search': {'icon': Icons.search, 'tags': ['search', 'find', 'magnify']},
      'filter_list': {'icon': Icons.filter_list, 'tags': ['filter', 'sort', 'list']},
      'sort': {'icon': Icons.sort, 'tags': ['sort', 'order', 'arrange']},
      'menu': {'icon': Icons.menu, 'tags': ['menu', 'hamburger', 'list']},
      'more_vert': {'icon': Icons.more_vert, 'tags': ['more', 'vertical', 'options']},
      'more_horiz': {'icon': Icons.more_horiz, 'tags': ['more', 'horizontal', 'options']},
      'apps': {'icon': Icons.apps, 'tags': ['apps', 'grid', 'all']},
      'widgets': {'icon': Icons.widgets, 'tags': ['widgets', 'components', 'blocks']},
      'extension': {'icon': Icons.extension, 'tags': ['extension', 'plugin', 'addon']},

      // Data & Sync
      'refresh': {'icon': Icons.refresh, 'tags': ['refresh', 'reload', 'update']},
      'sync': {'icon': Icons.sync, 'tags': ['sync', 'synchronize', 'update']},
      'update': {'icon': Icons.update, 'tags': ['update', 'refresh', 'renew']},
      'cloud_upload': {'icon': Icons.cloud_upload, 'tags': ['cloud', 'upload', 'save']},
      'cloud_download': {'icon': Icons.cloud_download, 'tags': ['cloud', 'download', 'get']},
      'cloud_done': {'icon': Icons.cloud_done, 'tags': ['cloud', 'done', 'synced']},
      'download': {'icon': Icons.download, 'tags': ['download', 'save', 'get']},
      'upload': {'icon': Icons.upload, 'tags': ['upload', 'send', 'put']},
      'file_upload': {'icon': Icons.file_upload, 'tags': ['file', 'upload', 'send']},
      'file_download': {'icon': Icons.file_download, 'tags': ['file', 'download', 'get']},
      'backup': {'icon': Icons.backup, 'tags': ['backup', 'save', 'cloud']},

      // Communication
      'share': {'icon': Icons.share, 'tags': ['share', 'send', 'export']},
      'send': {'icon': Icons.send, 'tags': ['send', 'share', 'transmit']},
      'reply': {'icon': Icons.reply, 'tags': ['reply', 'respond', 'back']},
      'forward': {'icon': Icons.forward, 'tags': ['forward', 'share', 'send']},
      'print': {'icon': Icons.print, 'tags': ['print', 'printer', 'output']},
      'email': {'icon': Icons.email, 'tags': ['email', 'mail', 'message']},
      'mail_outline': {'icon': Icons.mail_outline, 'tags': ['mail', 'outline', 'email']},
      'phone': {'icon': Icons.phone, 'tags': ['phone', 'call', 'telephone']},
      'phone_in_talk': {'icon': Icons.phone_in_talk, 'tags': ['phone', 'call', 'talking']},
      'chat': {'icon': Icons.chat, 'tags': ['chat', 'message', 'talk']},
      'chat_bubble': {'icon': Icons.chat_bubble, 'tags': ['chat', 'bubble', 'message']},
      'message': {'icon': Icons.message, 'tags': ['message', 'chat', 'text']},
      'sms': {'icon': Icons.sms, 'tags': ['sms', 'text', 'message']},
      'comment': {'icon': Icons.comment, 'tags': ['comment', 'feedback', 'message']},
      'forum': {'icon': Icons.forum, 'tags': ['forum', 'discussion', 'chat']},
      'contact_mail': {'icon': Icons.contact_mail, 'tags': ['contact', 'mail', 'email']},
      'contact_phone': {'icon': Icons.contact_phone, 'tags': ['contact', 'phone', 'call']},

      // Notifications & Status
      'notifications': {'icon': Icons.notifications, 'tags': ['notification', 'alert', 'bell']},
      'notifications_active': {'icon': Icons.notifications_active, 'tags': ['notification', 'active', 'alert']},
      'notifications_off': {'icon': Icons.notifications_off, 'tags': ['notification', 'off', 'muted']},
      'notification_important': {'icon': Icons.notification_important, 'tags': ['notification', 'important', 'alert']},
      'notification_add': {'icon': Icons.notification_add, 'tags': ['notification', 'add', 'new']},
      'priority_high': {'icon': Icons.priority_high, 'tags': ['priority', 'high', 'important']},

      // Files & Folders
      'folder': {'icon': Icons.folder, 'tags': ['folder', 'directory', 'files']},
      'folder_open': {'icon': Icons.folder_open, 'tags': ['folder', 'open', 'directory']},
      'create_new_folder': {'icon': Icons.create_new_folder, 'tags': ['folder', 'new', 'create']},
      'folder_special': {'icon': Icons.folder_special, 'tags': ['folder', 'special', 'star']},
      'insert_drive_file': {'icon': Icons.insert_drive_file, 'tags': ['file', 'document', 'page']},
      'image': {'icon': Icons.image, 'tags': ['image', 'picture', 'photo']},
      'photo': {'icon': Icons.photo, 'tags': ['photo', 'picture', 'image']},
      'photo_library': {'icon': Icons.photo_library, 'tags': ['photo', 'library', 'gallery']},
      'attach_file': {'icon': Icons.attach_file, 'tags': ['attach', 'file', 'clip']},
      'attachment': {'icon': Icons.attachment, 'tags': ['attachment', 'file', 'clip']},
      'link': {'icon': Icons.link, 'tags': ['link', 'url', 'chain']},
      'link_off': {'icon': Icons.link_off, 'tags': ['link', 'off', 'unlink']},

      // Favorites & Bookmarks
      'bookmark': {'icon': Icons.bookmark, 'tags': ['bookmark', 'save', 'favorite']},
      'bookmark_border': {'icon': Icons.bookmark_border, 'tags': ['bookmark', 'border', 'outline']},
      'favorite': {'icon': Icons.favorite, 'tags': ['favorite', 'heart', 'like']},
      'favorite_border': {'icon': Icons.favorite_border, 'tags': ['favorite', 'border', 'heart']},
      'thumb_up': {'icon': Icons.thumb_up, 'tags': ['thumbs up', 'like', 'approve']},
      'thumb_down': {'icon': Icons.thumb_down, 'tags': ['thumbs down', 'dislike', 'reject']},
      'thumb_up_alt': {'icon': Icons.thumb_up_alt, 'tags': ['thumbs up', 'alt', 'like']},
      'thumb_down_alt': {'icon': Icons.thumb_down_alt, 'tags': ['thumbs down', 'alt', 'dislike']},

      // User & Account
      'account_circle': {'icon': Icons.account_circle, 'tags': ['account', 'user', 'profile']},
      'account_box': {'icon': Icons.account_box, 'tags': ['account', 'user', 'box']},
      'badge': {'icon': Icons.badge, 'tags': ['badge', 'id', 'card']},
      'card_membership': {'icon': Icons.card_membership, 'tags': ['card', 'membership', 'id']},
      'login': {'icon': Icons.login, 'tags': ['login', 'sign in', 'enter']},
      'logout': {'icon': Icons.logout, 'tags': ['logout', 'sign out', 'exit']},
      'exit_to_app': {'icon': Icons.exit_to_app, 'tags': ['exit', 'logout', 'leave']},

      // Status & Verification
      'verified': {'icon': Icons.verified, 'tags': ['verified', 'check', 'approved']},
      'verified_user': {'icon': Icons.verified_user, 'tags': ['verified', 'user', 'secure']},
      'new_releases': {'icon': Icons.new_releases, 'tags': ['new', 'release', 'star']},
      'fiber_new': {'icon': Icons.fiber_new, 'tags': ['new', 'label', 'badge']},
      'upgrade': {'icon': Icons.upgrade, 'tags': ['upgrade', 'update', 'improve']},
      'gpp_good': {'icon': Icons.gpp_good, 'tags': ['good', 'shield', 'secure']},
      'gpp_bad': {'icon': Icons.gpp_bad, 'tags': ['bad', 'shield', 'insecure']},
      'gpp_maybe': {'icon': Icons.gpp_maybe, 'tags': ['maybe', 'shield', 'uncertain']},

      // Trends & Analytics
      'trending_up': {'icon': Icons.trending_up, 'tags': ['trending', 'up', 'increase']},
      'trending_down': {'icon': Icons.trending_down, 'tags': ['trending', 'down', 'decrease']},
      'trending_flat': {'icon': Icons.trending_flat, 'tags': ['trending', 'flat', 'stable']},
      'assessment': {'icon': Icons.assessment, 'tags': ['assessment', 'report', 'chart']},
      'insert_chart': {'icon': Icons.insert_chart, 'tags': ['chart', 'graph', 'insert']},

      // Device & System
      'battery_full': {'icon': Icons.battery_full, 'tags': ['battery', 'full', 'power']},
      'battery_charging_full': {'icon': Icons.battery_charging_full, 'tags': ['battery', 'charging', 'full']},
      'battery_alert': {'icon': Icons.battery_alert, 'tags': ['battery', 'alert', 'low']},
      'wifi': {'icon': Icons.wifi, 'tags': ['wifi', 'wireless', 'network']},
      'wifi_off': {'icon': Icons.wifi_off, 'tags': ['wifi', 'off', 'disconnected']},
      'signal_wifi_4_bar': {'icon': Icons.signal_wifi_4_bar, 'tags': ['wifi', 'signal', 'strong']},
      'bluetooth': {'icon': Icons.bluetooth, 'tags': ['bluetooth', 'wireless', 'device']},
      'bluetooth_connected': {'icon': Icons.bluetooth_connected, 'tags': ['bluetooth', 'connected', 'paired']},
      'signal_cellular_alt': {'icon': Icons.signal_cellular_alt, 'tags': ['signal', 'cellular', 'network']},
      'usb': {'icon': Icons.usb, 'tags': ['usb', 'connection', 'port']},
      'computer': {'icon': Icons.computer, 'tags': ['computer', 'desktop', 'pc']},
      'laptop': {'icon': Icons.laptop, 'tags': ['laptop', 'computer', 'notebook']},
      'phone_android': {'icon': Icons.phone_android, 'tags': ['phone', 'android', 'mobile']},
      'tablet': {'icon': Icons.tablet, 'tags': ['tablet', 'device', 'ipad']},
      'tv': {'icon': Icons.tv, 'tags': ['tv', 'television', 'monitor']},
      'watch': {'icon': Icons.watch, 'tags': ['watch', 'smartwatch', 'wearable']},
      'speaker': {'icon': Icons.speaker, 'tags': ['speaker', 'audio', 'sound']},
      'headphones': {'icon': Icons.headphones, 'tags': ['headphones', 'audio', 'listen']},
      'keyboard': {'icon': Icons.keyboard, 'tags': ['keyboard', 'input', 'type']},
      'mouse': {'icon': Icons.mouse, 'tags': ['mouse', 'pointer', 'input']},

      // Location & GPS
      'gps_fixed': {'icon': Icons.gps_fixed, 'tags': ['gps', 'location', 'fixed']},
      'gps_not_fixed': {'icon': Icons.gps_not_fixed, 'tags': ['gps', 'location', 'not fixed']},
      'gps_off': {'icon': Icons.gps_off, 'tags': ['gps', 'off', 'disabled']},
      'my_location': {'icon': Icons.my_location, 'tags': ['location', 'my', 'gps']},

      // View & Display
      'layers': {'icon': Icons.layers, 'tags': ['layers', 'stack', 'levels']},
      'layers_clear': {'icon': Icons.layers_clear, 'tags': ['layers', 'clear', 'remove']},
      'palette': {'icon': Icons.palette, 'tags': ['palette', 'color', 'paint']},
      'color_lens': {'icon': Icons.color_lens, 'tags': ['color', 'lens', 'palette']},
      'straighten': {'icon': Icons.straighten, 'tags': ['ruler', 'measure', 'straighten']},
      'category': {'icon': Icons.category, 'tags': ['category', 'group', 'organize']},
      'dashboard': {'icon': Icons.dashboard, 'tags': ['dashboard', 'overview', 'panel']},
      'space_dashboard': {'icon': Icons.space_dashboard, 'tags': ['space', 'dashboard', 'layout']},
      'view_list': {'icon': Icons.view_list, 'tags': ['list', 'view', 'items']},
      'view_module': {'icon': Icons.view_module, 'tags': ['grid', 'view', 'module']},
      'view_quilt': {'icon': Icons.view_quilt, 'tags': ['quilt', 'view', 'layout']},
      'view_agenda': {'icon': Icons.view_agenda, 'tags': ['agenda', 'view', 'list']},
      'view_column': {'icon': Icons.view_column, 'tags': ['column', 'view', 'layout']},
      'view_carousel': {'icon': Icons.view_carousel, 'tags': ['carousel', 'view', 'slider']},
      'grid_on': {'icon': Icons.grid_on, 'tags': ['grid', 'on', 'table']},
      'grid_off': {'icon': Icons.grid_off, 'tags': ['grid', 'off', 'table']},
      'table_chart': {'icon': Icons.table_chart, 'tags': ['table', 'chart', 'grid']},

      // Zoom & Screen
      'fullscreen': {'icon': Icons.fullscreen, 'tags': ['fullscreen', 'expand', 'maximize']},
      'fullscreen_exit': {'icon': Icons.fullscreen_exit, 'tags': ['fullscreen exit', 'minimize', 'restore']},
      'zoom_in': {'icon': Icons.zoom_in, 'tags': ['zoom', 'in', 'magnify']},
      'zoom_out': {'icon': Icons.zoom_out, 'tags': ['zoom', 'out', 'reduce']},
      'zoom_in_map': {'icon': Icons.zoom_in_map, 'tags': ['zoom', 'in', 'map']},
      'zoom_out_map': {'icon': Icons.zoom_out_map, 'tags': ['zoom', 'out', 'map']},
      'fit_screen': {'icon': Icons.fit_screen, 'tags': ['fit', 'screen', 'resize']},
      'aspect_ratio': {'icon': Icons.aspect_ratio, 'tags': ['aspect', 'ratio', 'resize']},

      // Image Editing
      'crop': {'icon': Icons.crop, 'tags': ['crop', 'cut', 'trim']},
      'crop_square': {'icon': Icons.crop_square, 'tags': ['crop', 'square', 'trim']},
      'crop_free': {'icon': Icons.crop_free, 'tags': ['crop', 'free', 'selection']},
      'rotate_left': {'icon': Icons.rotate_left, 'tags': ['rotate', 'left', 'turn']},
      'rotate_right': {'icon': Icons.rotate_right, 'tags': ['rotate', 'right', 'turn']},
      'rotate_90_degrees_ccw': {'icon': Icons.rotate_90_degrees_ccw, 'tags': ['rotate', '90', 'ccw']},
      'flip': {'icon': Icons.flip, 'tags': ['flip', 'mirror', 'reverse']},
      'flip_camera_android': {'icon': Icons.flip_camera_android, 'tags': ['flip', 'camera', 'switch']},
      'transform': {'icon': Icons.transform, 'tags': ['transform', 'rotate', 'scale']},
      'brightness_high': {'icon': Icons.brightness_high, 'tags': ['brightness', 'light', 'sun']},
      'brightness_medium': {'icon': Icons.brightness_medium, 'tags': ['brightness', 'medium', 'light']},
      'brightness_low': {'icon': Icons.brightness_low, 'tags': ['brightness', 'dark', 'dim']},
      'brightness_auto': {'icon': Icons.brightness_auto, 'tags': ['brightness', 'auto', 'adaptive']},
      'contrast': {'icon': Icons.contrast, 'tags': ['contrast', 'adjust', 'image']},
      'tonality': {'icon': Icons.tonality, 'tags': ['tonality', 'adjust', 'image']},
      'gradient': {'icon': Icons.gradient, 'tags': ['gradient', 'blend', 'color']},

      // Media Controls
      'play_arrow': {'icon': Icons.play_arrow, 'tags': ['play', 'start', 'media']},
      'pause': {'icon': Icons.pause, 'tags': ['pause', 'stop', 'media']},
      'stop': {'icon': Icons.stop, 'tags': ['stop', 'end', 'media']},
      'skip_next': {'icon': Icons.skip_next, 'tags': ['skip', 'next', 'forward']},
      'skip_previous': {'icon': Icons.skip_previous, 'tags': ['skip', 'previous', 'back']},
      'fast_forward': {'icon': Icons.fast_forward, 'tags': ['fast', 'forward', 'media']},
      'fast_rewind': {'icon': Icons.fast_rewind, 'tags': ['fast', 'rewind', 'media']},
      'replay': {'icon': Icons.replay, 'tags': ['replay', 'repeat', 'again']},
      'repeat': {'icon': Icons.repeat, 'tags': ['repeat', 'loop', 'again']},
      'repeat_one': {'icon': Icons.repeat_one, 'tags': ['repeat', 'one', 'single']},
      'shuffle': {'icon': Icons.shuffle, 'tags': ['shuffle', 'random', 'mix']},
      'volume_up': {'icon': Icons.volume_up, 'tags': ['volume', 'up', 'loud']},
      'volume_down': {'icon': Icons.volume_down, 'tags': ['volume', 'down', 'quiet']},
      'volume_off': {'icon': Icons.volume_off, 'tags': ['volume', 'off', 'mute']},
      'volume_mute': {'icon': Icons.volume_mute, 'tags': ['volume', 'mute', 'silent']},

      // Shopping & Commerce
      'shopping_cart': {'icon': Icons.shopping_cart, 'tags': ['shopping', 'cart', 'buy']},
      'shopping_bag': {'icon': Icons.shopping_bag, 'tags': ['shopping', 'bag', 'purchase']},
      'shopping_basket': {'icon': Icons.shopping_basket, 'tags': ['shopping', 'basket', 'buy']},
      'store': {'icon': Icons.store, 'tags': ['store', 'shop', 'market']},
      'storefront': {'icon': Icons.storefront, 'tags': ['storefront', 'shop', 'store']},
      'local_offer': {'icon': Icons.local_offer, 'tags': ['offer', 'tag', 'sale']},
      'local_atm': {'icon': Icons.local_atm, 'tags': ['atm', 'money', 'cash']},
      'credit_card': {'icon': Icons.credit_card, 'tags': ['credit', 'card', 'payment']},
      'payment': {'icon': Icons.payment, 'tags': ['payment', 'card', 'money']},
      'attach_money': {'icon': Icons.attach_money, 'tags': ['money', 'dollar', 'currency']},
      'currency_exchange': {'icon': Icons.currency_exchange, 'tags': ['currency', 'exchange', 'money']},
      'receipt': {'icon': Icons.receipt, 'tags': ['receipt', 'bill', 'invoice']},
      'qr_code': {'icon': Icons.qr_code, 'tags': ['qr', 'code', 'scan']},
      'qr_code_scanner': {'icon': Icons.qr_code_scanner, 'tags': ['qr', 'scanner', 'code']},
      'barcode_reader': {'icon': Icons.barcode_reader, 'tags': ['barcode', 'reader', 'scan']},

      // Food & Drink
      'restaurant': {'icon': Icons.restaurant, 'tags': ['restaurant', 'food', 'dining']},
      'local_dining': {'icon': Icons.local_dining, 'tags': ['dining', 'food', 'restaurant']},
      'local_cafe': {'icon': Icons.local_cafe, 'tags': ['cafe', 'coffee', 'drink']},
      'local_bar': {'icon': Icons.local_bar, 'tags': ['bar', 'drink', 'alcohol']},
      'local_pizza': {'icon': Icons.local_pizza, 'tags': ['pizza', 'food', 'dining']},

      // Places & Buildings
      'business': {'icon': Icons.business, 'tags': ['business', 'building', 'office']},
      'apartment': {'icon': Icons.apartment, 'tags': ['apartment', 'building', 'home']},
      'house': {'icon': Icons.house, 'tags': ['house', 'home', 'building']},
      'cottage': {'icon': Icons.cottage, 'tags': ['cottage', 'house', 'home']},
      'villa': {'icon': Icons.villa, 'tags': ['villa', 'house', 'home']},
      'factory': {'icon': Icons.factory, 'tags': ['factory', 'industrial', 'building']},
      'warehouse': {'icon': Icons.warehouse, 'tags': ['warehouse', 'storage', 'building']},
      'school': {'icon': Icons.school, 'tags': ['school', 'education', 'building']},
      'church': {'icon': Icons.church, 'tags': ['church', 'religion', 'building']},
      'domain': {'icon': Icons.domain, 'tags': ['domain', 'building', 'office']},

      // Miscellaneous
      'desktop_windows': {'icon': Icons.desktop_windows, 'tags': ['desktop', 'windows', 'computer']},
      'developer_mode': {'icon': Icons.developer_mode, 'tags': ['developer', 'mode', 'code']},
      'code': {'icon': Icons.code, 'tags': ['code', 'programming', 'dev']},
      'bug_report': {'icon': Icons.bug_report, 'tags': ['bug', 'report', 'issue']},
      'campaign': {'icon': Icons.campaign, 'tags': ['campaign', 'megaphone', 'announce']},
      'sports': {'icon': Icons.sports, 'tags': ['sports', 'activity', 'fitness']},
      'fitness_center': {'icon': Icons.fitness_center, 'tags': ['fitness', 'gym', 'exercise']},
      'push_pin': {'icon': Icons.push_pin, 'tags': ['pin', 'push', 'marker']},
      'push_pin_outlined': {'icon': Icons.push_pin_outlined, 'tags': ['pin', 'outlined', 'marker']},
    };

    for (final entry in iconMap.entries) {
      final iconData = entry.value['icon'] as IconData;
      final tags = entry.value['tags'] as List<String>;

      icons.add(IconMetadata(
        file: 'material_${entry.key}.icon',
        name: _formatIconName(entry.key),
        category: IconCategory.equipment,
        keywords: ['material', 'icon', ...tags],
        metadata: {'iconData': iconData, 'type': 'material'},
      ));
    }

    return icons;
  }

  static String _formatIconName(String iconKey) {
    return iconKey
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static Future<List<IconMetadata>> loadPostingsFromJson() async {
    final icons = <IconMetadata>[];

    try {
      // Try several likely locations for postings.json. Some Flutter web builds
      // place assets under `assets/` and end up with `assets/assets/...` on
      // the published site; try both variants so the web app can find the file.
      final candidatePaths = [
        'assets/postings.json',
        'assets/assets/postings.json',
        'postings.json',
      ];

      String? jsonString;
      String? usedPath;
      for (final p in candidatePaths) {
        try {
          jsonString = await rootBundle.loadString(p);
          usedPath = p;
          break;
        } catch (_) {
          // try next
        }
      }

      if (jsonString == null) {
        throw Exception('postings.json not found in any known asset location');
      }

      print('Loaded postings.json from: $usedPath (length: ${jsonString.length})');

      final jsonData = json.decode(jsonString);
      final postingsList = jsonData['postings'] as List<dynamic>;
      print('Found ${postingsList.length} postings');

      // Load AssetManifest to determine actual deployed asset keys so we can
      // correct svg asset paths if Flutter web nested them under another `assets/`.
      Set<String> assetKeys = {};
      try {
        String? manifestStr;
        try {
          manifestStr = await rootBundle.loadString('AssetManifest.json');
        } catch (_) {
          // fallback path
          manifestStr = await rootBundle.loadString('assets/AssetManifest.json');
        }
        final manifestJson = json.decode(manifestStr) as Map<String, dynamic>;
        assetKeys = manifestJson.keys.map((k) => k.toString()).toSet();
        print('AssetManifest loaded, ${assetKeys.length} keys');
      } catch (e) {
        print('Could not load AssetManifest to normalize asset paths: $e');
      }

      // Convert each posting to IconMetadata
      for (final postingJson in postingsList) {
        final posting = PostingMetadata.fromJson(postingJson);

        // Determine the actual asset path to use at runtime. The posting
        // metadata contains `svgAssetPath` (e.g. 'assets/Postings/Slide1.svg').
        // On some builds the actual served key is 'assets/assets/Postings/...'
        // so try variants and prefer the one present in AssetManifest.
        String chosenAssetPath = posting.svgAssetPath;
        if (assetKeys.isNotEmpty) {
          final candidates = <String>{
            posting.svgAssetPath,
            'assets/${posting.svgAssetPath}',
            posting.svgAssetPath.replaceFirst(RegExp('^assets/'), ''),
          };
          final found = candidates.firstWhere(
            (c) => assetKeys.contains(c),
            orElse: () => posting.svgAssetPath,
          );
          chosenAssetPath = found;
        }

        icons.add(IconMetadata(
          file: posting.svgFilename,
          name: '${posting.id} - ${posting.header}',
          category: IconCategory.posting,
          keywords: posting.tags.toList(),
          assetPath: chosenAssetPath,
          metadata: posting,
        ));
      }

      print('Successfully loaded ${icons.length} posting icons');
    } catch (e, stackTrace) {
      print('Error loading postings.json: $e');
      print('Stack trace: $stackTrace');
    }

    return icons;
  }

  static List<IconMetadata> loadEmbeddedIcons() {
    // No embedded icons - all icons loaded from postings.json
    return [];
  }
}
