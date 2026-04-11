import '../../models/scene_models.dart';
import 'app_localizations.dart';

/// Tiếng Việt
class AppLocalizationsVi extends AppLocalizations {
  @override
  String get ok => 'OK';
  
  @override
  String get cancel => 'Hủy';
  
  @override
  String get save => 'Lưu';
  
  @override
  String get open => 'Mở';
  
  @override
  String get reset => 'Đặt lại';
  
  @override
  String get edit => 'Sửa';
  
  @override
  String get load => 'Tải';
  
  @override
  String get livingRoom => 'Phòng khách';
  
  @override
  String get garden => 'Khu vườn';
  
  @override
  String get aquarium => 'Bể cá';
  
  @override
  String get paintingRoom => 'Phòng tranh';
  
  @override
  String get musicRoom => 'Phòng nhạc';

  @override
  String get tasks => 'Công việc';

  @override
  String get mood => 'Tâm trạng';

  @override
  String get draw => 'Vẽ';

  @override
  String get compose => 'Sáng tác';

  @override
  String get library => 'Thư viện';
  
  @override
  String get templates => 'Mẫu vẽ';
  
  @override
  String get samples => 'Mẫu nhạc';
  
  @override
  String get useTemplate => 'Sử dụng mẫu này?';
  
  @override
  String get useSample => 'Sử dụng mẫu nhạc này?';
  
  @override
  String get selectTemplate => 'Chọn mẫu vẽ';
  
  @override
  String get selectSample => 'Chọn mẫu nhạc';
  
  @override
  String currentWillBeReplaced(String type) {
    final typeVi = type == 'drawing' ? 'bức tranh hiện tại' : 'bản nhạc hiện tại';
    return '$typeVi sẽ bị thay thế.';
  }
  
  @override
  String get templateHeart => 'Trái tim';
  
  @override
  String get templateStar => 'Ngôi sao';
  
  @override
  String get templateFlower => 'Hoa';
  
  @override
  String get templateApple => 'Quả táo';
  
  @override
  String get templateTree => 'Cây';
  
  @override
  String get templateCat => 'Mèo';
  
  @override
  String get settings => 'Cài đặt';
  
  @override
  String get theme => 'Giao diện';
  
  @override
  String get language => 'Ngôn ngữ';
  
  @override
  String get audio => 'Âm thanh';
  
  @override
  String get bgm => '♬ BGM:';
  
  @override
  String get volume => 'Âm lượng:';
  
  @override
  String get sfx => '🔊 SFX:';
  
  @override
  String get enabled => 'Bật';

  @override
  String get display => 'Hiển thị';
  
  @override
  String get preview => 'Xem trước:';
  
  @override
  String get mascot => 'Linh vật';
  
  @override
  String get name => 'Tên';
  
  @override
  String get mascotName => 'Mèo';
  
  @override
  String get notification => 'Thông báo';
  
  @override
  String get sleepReminder => 'Nhắc ngủ';
  
  @override
  String get taskReminder => 'Nhắc công việc';
  
  @override
  String get time => 'Thời gian';
  
  @override
  String get before => 'Trước';
  
  @override
  String get remindBeforeMinutes => 'Nhắc trước (phút)';
  
  @override
  String get minutes => 'phút';
  
  @override
  String get cloudSync => 'Đồng bộ Cloud';
  
  @override
  String get sync => 'Đồng bộ';
  
  @override
  String get resetToDefault => 'Đặt lại mặc định';

  @override
  String get resetConfirmation => 'Bạn có chắc muốn đặt lại tất cả cài đặt?';

  @override
  String get scheduleTask => 'Lịch công việc';

  @override
  String get taskName => 'Tên công việc';

  @override
  String get addTask => 'Thêm công việc';

  @override
  String get noTasksYet => 'Chưa có công việc nào!';

  @override
  String get expectedPoints => 'Điểm dự kiến';

  @override
  String get endDayAndClaimPoints => 'Kết thúc ngày & Nhận điểm';

  @override
  String get completedTasks => 'công việc hoàn thành';

  @override
  String get alreadyClaimedToday => 'Đã nhận điểm hôm nay rồi!';

  @override
  String get noCompletedTasks => 'Chưa có công việc nào hoàn thành!';

  @override
  String get sceneShop => 'Cửa hàng bối cảnh';

  @override
  String get scenePreviewExpand => 'Xem tất cả phòng';

  @override
  String get scenePreviewCollapse => 'Thu gọn';

  @override
  String get progress => 'Tiến trình';

  @override
  String get emotionDiary => 'Nhật ký cảm xúc';

  @override
  String get historyLast2Weeks => 'Lịch sử 2 tuần';

  @override
  String get tapDayToViewDetails => 'Chạm vào ngày để xem chi tiết';

  @override
  String get noDiaryData => 'Chưa có dữ liệu nhật ký';

  @override
  String get todaysJournal => 'Nhật ký hôm nay';

  @override
  String get dailyJournal => 'Nhật ký hằng ngày';

  @override
  String get howDoYouFeelOverall => 'Bạn cảm thấy thế nào?';

  @override
  String get howWasYourStressLevel => 'Mức độ căng thẳng?';

  @override
  String get howProductiveWereYou => 'Mức độ làm việc?';

  @override
  String get veryBad => 'Rất tệ';

  @override
  String get bad => 'Tệ';

  @override
  String get neutral => 'Bình thường';

  @override
  String get good => 'Tốt';

  @override
  String get great => 'Rất tốt';

  @override
  String get veryHigh => 'Rất cao';

  @override
  String get high => 'Cao';

  @override
  String get moderate => 'Trung bình';

  @override
  String get low => 'Thấp';

  @override
  String get relaxed => 'Thư giãn';

  @override
  String get none => 'Không';

  @override
  String get little => 'Ít';

  @override
  String get average => 'Trung bình';

  @override
  String get very => 'Nhiều';

  @override
  String get writeYourThoughts => 'Viết suy nghĩ của bạn...';

  @override
  String get saveToEarnPoints => '✨ Lưu để nhận điểm!';

  @override
  String get alreadySavedToday => '✅ Đã lưu hôm nay';

  // Garden
  @override
  String get gardenTitle => 'KHU VƯỜN';

  @override
  String get inventory => 'KHO ĐỒ';

  // Aquarium
  @override
  String get fish => 'con cá';

  @override
  String get hour => 'giờ';

  @override
  String get price => 'Giá';

  @override
  String get lastFed => 'Cho ăn lần cuối:';

  @override
  String get fishShop => 'CỬA HÀNG CÁ';

  @override
  String get owned => 'sở hữu';

  @override
  String get noFishYet => 'Chưa có cá nào!';

  @override
  String get buyFishBelow => 'Mua cá ở dưới.';

  @override
  String get betta => 'Cá Betta';

  @override
  String get guppy => 'Cá Guppy';

  @override
  String get neonTetra => 'Cá Neon Tetra';

  @override
  String get molly => 'Cá Molly';

  @override
  String get cory => 'Cá Cory';

  @override
  String get platy => 'Cá Platy';

  @override
  String get tankFull => 'BỂ ĐẦY';

  @override
  String get fishHungry => 'đói';

  // ==================== ROCK BALANCING LAN ====================
  @override String get players => 'Người chơi';
  @override String get rockBalancing => 'Xếp đá';
  @override String get lanNotConnected => 'Cần kết nối LAN trước khi chơi';
  @override String get rockCount => 'Số viên đá';
  @override String get joinGame => 'Tham gia';
  @override String get startGame => 'Bắt đầu';
  @override String get approveJoin => 'Duyệt người chơi tham gia';
  @override String get approveLabel => 'Chấp nhận';
  @override String get remove => 'Gỡ';
  @override String get pendingApproval => 'Chờ chủ phòng xác nhận...';
  @override String get deniedByHost => 'Yêu cầu tham gia bị từ chối';
  @override String get kickedByHost => 'Bạn đã bị gỡ khỏi phòng';
  @override String get waitingForPlayers => 'Chờ người chơi...';
  @override String get readyLabel => 'Sẵn sàng';
  @override String get notReadyLabel => 'Chưa sẵn sàng';
  @override String get lobbyHost => 'Chủ phòng';
  @override String get singleplayer => 'Chơi đơn';
  @override String get multiplayer => 'Chơi chung';
  @override String get createRoom => 'Tạo phòng';
  @override String get scanning => 'Đang tìm kiếm...';
  @override String get startServer => 'Đang khởi động máy chủ...';
  @override String get connecting => 'Đang kết nối...';
  @override String get reconnecting => 'Đang kết nối lại...';
  @override String get hostsFound => 'Tìm thấy phòng';
  @override String get rescan => 'Quét lại';
  @override String get connectionLost => 'Mất kết nối';
  @override String get restartServer => 'Khởi động lại máy chủ';
  @override String get reconnect => 'Kết nối lại';
  @override String get syncError => 'Đồng bộ thất bại';
  @override String get record => 'Kỷ lục';
  @override String get endGame => 'Kết thúc';
  @override String get rocksStacked => 'Viên đá xếp lên';
  @override String get maxHeightLabel => 'Chiều cao tối đa';

  // Paper Ship
  @override String get paperShip => 'Thuyền Giấy';

  // Firefly Catching
  @override String get fireflyCatching => 'Hứng Đom Đóm';
  @override String get jar => 'Lọ';
  @override String get lamp => 'Đèn';
  @override String get caught => 'Đã bắt';
  @override String get attractMode => 'Thu hút';
  @override String get repelMode => 'Xua đuổi';
  @override String get attractShort => 'Hút';
  @override String get repelShort => 'Đẩy';
  @override String get maxFireflyCount => 'Số đom đóm tối đa trên màn hình';
  @override String get roleJar => 'Người cầm lọ';
  @override String get roleLamp => 'Người cầm đèn';
  @override String get switchTool => 'Đổi';
  @override String get selectStartingRole => 'Chọn vai trò khởi đầu';

  // Painting Room
  @override
  String get art => 'Vẽ tranh';

  @override
  String get canvasName => 'Tên tranh';

  @override
  String get clear => 'Xóa';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get colorPalette => 'BẢNG MÀU';

  @override
  String get selected => 'Đang chọn';

  @override
  String get clearCanvas => 'Xóa Canvas?';

  @override
  String get clearCanvasWarning => 'Xóa';

  @override
  String get thisWillEraseEverything => 'Điều này sẽ xóa tất cả!';
  
  @override
  String get gallery => 'Thư viện';
  
  @override
  String get myPaintings => 'Tranh của tôi';
  
  @override
  String paintingNumber(int number) => 'Tranh $number';
  
  @override
  String get zoom => 'Phóng to';
  
  @override
  String get myTracks => 'Bản nhạc của tôi';

  // Music Room
  @override
  String get music => 'Âm nhạc';
  
  @override
  String get songName => 'Tên bài hát';
  
  @override
  String get selectInstrument => 'CHỌN NHẠC CỤ';
  
  @override
  String get notes => 'NỐT NHẠC (chạm để đặt lên timeline)';
  
  @override
  String get note => 'Nốt';
  
  @override
  String get piano => 'Piano';
  
  @override
  String get guitar => 'Guitar';
  
  @override
  String get synth => 'Synth';
  
  @override
  String get bass => 'Bass';
  
  @override
  String get drum => 'Trống';
  
  // Scene Shop
  @override
  String get yourPoints => 'Điểm của bạn';
  
  @override
  String get buyCollection => 'Mua bối cảnh';
  
  @override
  String get useCollection => 'Sử dụng bối cảnh';
  
  @override
  String get currentlyUsing => 'Đang sử dụng';
  
  @override
  String get notEnoughPoints => 'Không đủ điểm';
  
  @override
  String get points => 'Điểm';
  
  @override
  String get free => 'MIỄN PHÍ';

  @override
  String get ownedBadge => '✓ Sở hữu';
  
  @override
  String get cozyHome => 'Ngôi nhà ấm cúng';
  
  @override
  String get forest => 'Rừng xanh';
  
  @override
  String get beach => 'Bãi biển';
  
  @override
  String get peachBlossom => 'Hoa anh đào';

  @override
  String get winter => 'Mùa đông';

  @override
  String get desert => 'Ốc đảo sa mạc';

  @override
  String get cosmic => 'Đêm vũ trụ';

  @override
  String get castle => 'Lâu đài đá';

  @override
  String get cozyHomeDesc => 'Những khung cảnh ấm cúng tại nhà';

  @override
  String get forestDesc => 'Khung cảnh rừng xanh yên bình';

  @override
  String get beachDesc => 'Khung cảnh biển thư giãn';

  @override
  String get peachBlossomDesc => 'Hoa đào, ao cá koi và bàn gỗ thấp';

  @override
  String get winterDesc => 'Xứ sở mùa đông ấm áp';

  @override
  String get desertDesc => 'Cồn cát, ánh vàng hổ phách và điểm nhấn đất son';

  @override
  String get cosmicDesc => 'Bầu trời sao, tím thẫm và sắc tinh vân lung linh';

  @override
  String get castleDesc => 'Hành lang đá cuội, đá xám mát và hơi ấm trung cổ';

  // Authentication
  @override
  String get signUp => 'Đăng ký';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản?';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get enterEmail => 'Nhập email';

  @override
  String get enterPassword => 'Nhập mật khẩu';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get invalidEmail => 'Email không hợp lệ';

  @override
  String get letsGetStarted => 'Bắt đầu nào!';

  @override
  String get welcomeBack => 'Chào mừng trở lại!';

  @override
  String get dontHaveAccount => 'Chưa có tài khoản?';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordDescription => 'Đừng lo! Nhập địa chỉ email và chúng tôi sẽ gửi link đặt lại mật khẩu.';

  @override
  String get forgotPasswordEmailSentDescription => 'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến email của bạn.';

  @override
  String get sendResetEmail => 'Gửi email đặt lại';

  @override
  String get emailSent => 'Đã gửi email!';

  @override
  String get emailSentSuccessfully => 'Đã gửi email đặt lại mật khẩu thành công!';

  @override
  String get checkYourInbox => 'Kiểm tra hộp thư và làm theo hướng dẫn để đặt lại mật khẩu.';

  @override
  String get sendAgain => 'Gửi lại';

  @override
  String get rememberPassword => 'Nhớ lại mật khẩu?';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get pleaseLoginFirst => 'Vui lòng đăng nhập trước để đồng bộ dữ liệu';

  @override
  String get syncing => 'Đang đồng bộ...';

  @override
  String get login => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get useAsGuest => 'Dùng như khách';

  @override
  String get usingAsGuestMessage => 'Đang dùng như khách. Bạn có thể đăng ký bất cứ lúc nào!';

  @override
  String get failedToStartGuestMode => 'Không thể bắt đầu chế độ khách';

  @override
  String get welcomeUpgradedFromGuest => 'Chào mừng! Đã nâng cấp từ chế độ khách thành công!';

  @override
  String get registrationSuccessful => 'Đăng ký thành công!';

  @override
  String get loginSuccessful => 'Đăng nhập thành công!';

  @override
  String get upgradedFromGuestMode => 'Chào mừng! Đã nâng cấp từ chế độ khách.';

  @override
  String get syncWillRetryLater => 'Sync sẽ thử lại sau.';

  // Welcome Screen
  @override
  String get chooseYourTheme => 'Chọn giao diện';

  @override
  String get pickColorScheme => 'Chọn bảng màu phù hợp với tâm trạng của bạn';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get choosePreferredLanguage => 'Chọn ngôn ngữ ưa thích của bạn';

  @override
  String get audioSettings => 'Cài đặt âm thanh';

  @override
  String get customizeAudioExperience => 'Tùy chỉnh trải nghiệm âm thanh';

  @override
  String get backgroundMusic => 'Nhạc nền';

  @override
  String get soundEffects => 'Hiệu ứng âm thanh';

  @override
  String get enableSFX => 'Bật SFX';

  @override
  String get back => 'Quay lại';

  @override
  String get next => 'Tiếp theo';

  @override
  String get getStarted => 'Bắt đầu! 🎉';

  // Tutorial Screen
  @override
  String get tutorialTitle => 'Hướng dẫn sử dụng';

  @override
  String get tutorialOverviewTitle => 'Tổng quan & Công cụ hàng ngày';

  @override
  String get tutorialOverviewDesc => 'Đồng hành cùng linh vật đáng yêu khám phá 5 không gian ấm cúng. Phòng khách là nơi bạn chăm sóc thân tâm — từ lập kế hoạch ngày mới, ghi chép cảm xúc đến luyện thở và cải thiện giấc ngủ.';

  @override
  String get tutorialTipPrefix => 'Mẹo: Nhấn biểu tượng';
  @override
  String get tutorialTipSuffix => 'ở góc trên bên trái để xem hướng dẫn chi tiết khi sử dụng chúng.';

  @override
  String get tutorialLifestyleSupportTitle => 'Kết nối bạn bè (LAN)';

  @override
  String get tutorialLifestyleSupportDesc => 'Gắn kết hơn khi chơi cùng bạn bè qua mạng Wi-Fi nội bộ. Cùng nhau chinh phục thử thách xếp đá cân bằng, hoặc phối hợp bắt đom đóm — một người giữ lọ, một người dẫn đường. Bắt đầu ngay tại phòng khách!';

  @override
  String get tutorialRewardingTitle => 'Mini-game & Phần thưởng';

  @override
  String get tutorialRewardingDesc => 'Tích lũy điểm thưởng qua các hoạt động thư giãn: chăm sóc vườn cây xanh mát hay nuôi cá trong bể. Dùng điểm để thay đổi diện mạo mới cho ngôi nhà tại Cửa hàng không gian.';

  @override
  String get tutorialCreativeTitle => 'Không gian Sáng tạo';

  @override
  String get tutorialCreativeDesc => 'Thỏa sức sáng tạo tại Phòng tranh với bảng màu rực rỡ và lưu giữ tác phẩm tại thư viện riêng. Ghé thăm Phòng nhạc để tự tay soạn những giai điệu chữa lành từ các nhạc cụ độc đáo.';

  @override
  String get tutorialPrevious => 'Trước';

  @override
  String get tutorialNext => 'Tiếp';

  @override
  String get tutorialGotIt => 'Đã hiểu!';

  @override
  String get tutorialSkip => 'Bỏ qua';

  @override
  String tutorialPageOf(int current, int total) => 'Trang $current/$total';

  // Tutorial overlays — Sleep Guide
  @override
  String get tutorialSleepTipTitle => 'Mẹo Giấc Ngủ Hôm Nay';
  @override
  String get tutorialSleepTipDesc => 'Thẻ linh vật hiển thị mẹo dựa trên giờ ngủ của bạn. Thẻ phía dưới cung cấp thêm các mẹo ngẫu nhiên khác.';
  @override
  String get tutorialSleepGridTitle => 'Lịch Sử Hai Tuần';
  @override
  String get tutorialSleepGridDesc => 'Mỗi ô hiển thị chất lượng giấc ngủ qua biểu tượng cảm xúc. Nhấn để xem hoặc chỉnh sửa bản ghi đêm đó.';
  @override
  String get tutorialSleepGraphTitle => 'Biểu Đồ Giấc Ngủ';
  @override
  String get tutorialSleepGraphDesc => 'Chuyển đổi giữa Thời lượng và Chất lượng để theo dõi xu hướng giấc ngủ trong 14 ngày qua.';
  @override
  String get tutorialSleepCheckinTitle => 'Nhắc Nhở Giấc Ngủ';
  @override
  String get tutorialSleepCheckinDesc => 'Đặt giờ ngủ và giờ thức mục tiêu để nhận thông báo nhắc nhở nhẹ nhàng hàng ngày.';

  // Tutorial overlays — Drawing
  @override
  String get tutorialDrawCanvasTitle => 'Canvas Pixel';
  @override
  String get tutorialDrawCanvasDesc => 'Nhấn hoặc kéo trên lưới để tô màu cho từng ô pixel.';
  @override
  String get tutorialDrawToolbarTitle => 'Thanh Công Cụ';
  @override
  String get tutorialDrawToolbarDesc => 'Đặt tên tranh, hoàn tác nét vẽ, xóa bảng vẽ, mở tranh đã lưu hoặc tải mẫu gợi ý có sẵn để bắt đầu nhanh.';
  @override
  String get tutorialDrawZoomTitle => 'Thu Phóng & Di Chuyển';
  @override
  String get tutorialDrawZoomDesc => 'Dùng các nút mũi tên để di chuyển và +/− để phóng to/thu nhỏ khi vẽ chi tiết.';
  @override
  String get tutorialDrawPaletteTitle => 'Bảng Màu';
  @override
  String get tutorialDrawPaletteDesc => 'Nhấn để chọn màu. Ô có viền nổi bật là màu bạn đang sử dụng.';

  // Tutorial overlays — Composing
  @override
  String get tutorialComposeToolbarTitle => 'Thanh Quản Lý';
  @override
  String get tutorialComposeToolbarDesc => 'Đặt tên cho bản nhạc tại đây. Mọi thay đổi sẽ được tự động lưu lại.';
  @override
  String get tutorialComposeTimelineTitle => 'Dòng Thời Gian';
  @override
  String get tutorialComposeTimelineDesc => 'Mỗi hàng là một nhạc cụ, mỗi cột là một nhịp. Nhấn vào ô để đặt hoặc xóa nốt nhạc.';
  @override
  String get tutorialComposePlaybackTitle => 'Trình Phát';
  @override
  String get tutorialComposePlaybackDesc => 'Nhấn Phát để nghe lặp liên tục hoặc Dừng để quay về nhịp đầu tiên. Mở nhạc đã lưu hoặc khám phá mẫu âm thanh từ thư viện.';
  @override
  String get tutorialComposeNotesTitle => 'Nhạc Cụ & Nốt Nhạc';
  @override
  String get tutorialComposeNotesDesc => 'Chọn nhạc cụ ở hàng trên, sau đó chọn nốt (Đô–Đô, 8 nốt) — có thể chạm để chơi trực tiếp hoặc chọn để đặt vào dòng thời gian.';

  // Tutorial overlays — Emotion Diary
  @override
  String get tutorialDiaryHistoryTitle => 'Lịch Sử Tâm Trạng';
  @override
  String get tutorialDiaryHistoryDesc => 'Lưới hiển thị tâm trạng theo tuần và biểu đồ biểu diễn xu hướng cảm xúc của bạn.';
  @override
  String get tutorialDiaryQuestionsTitle => 'Ghi Chép Hàng Ngày';
  @override
  String get tutorialDiaryQuestionsDesc => 'Đánh giá tâm trạng, mức căng thẳng và năng suất (thang 1–5). Cần hoàn thành cả ba để lưu.';
  @override
  String get tutorialDiaryNotesTitle => 'Ghi Chú Cá Nhân';
  @override
  String get tutorialDiaryNotesDesc => 'Tự do viết về ngày của bạn — suy nghĩ, cảm xúc hoặc bất cứ điều gì (Tối đa 400 ký tự).';
  @override
  String get tutorialDiarySaveTitle => 'Lưu Nhật Ký';
  @override
  String get tutorialDiarySaveDesc => 'Nhấn Lưu sau khi đánh giá. Bạn có thể cập nhật nội dung bất cứ lúc nào trước nửa đêm.';

  // Theme names
  @override
  String get themePastelBlueBreeze => 'Làn gió xanh dương';

  @override
  String get themeCalmLavender => 'Tím oải hương';

  @override
  String get themeWarmAmber => 'Hổ Phách';

  @override
  String get themeMintyFresh => 'Xanh bạc hà';

  @override
  String get themeMidnightBlue => 'Xanh đêm';

  @override
  String get themeSoftPurpleNight => 'Đêm tím nhẹ';

  @override
  String get themeWarmSunset => 'Hoàng hôn ấm';

  @override
  String get themeSereneGreenNight => 'Đêm xanh tĩnh lặng';

  // BGM names
  @override
  String get bgmLofiBeats => 'Nhạc Lofi';

  @override
  String get bgmRainSounds => 'Tiếng mưa';

  @override
  String get bgmPianoMusic => 'Nhạc piano';

  @override
  String get bgmAcousticBallad => 'Ballad nhẹ nhàng';

  @override
  String get bgmFolkSong => 'Dân ca';

  @override
  String get bgmIndieVibes => 'Nhạc indie';

  @override
  String get bgmSoftPop => 'Pop nhẹ nhàng';

  @override
  String get bgmChillAcoustic => 'Acoustic thư giãn';

  // Mascot dialogues - Lời chào khi chuyển scene (2 biến thể mỗi scene)
  @override
  String getMascotSceneGreeting(SceneType scene, int variant) {
    switch (scene) {
      case SceneType.livingRoom:
        return variant == 0
            ? "Chào mừng về nhà! Sẵn sàng cho một ngày hiệu quả chưa?"
            : "Cùng xem chúng ta có thể hoàn thành gì hôm nay!";
      case SceneType.garden:
        return variant == 0
            ? "Đến lúc chăm sóc vườn rồi! Không khí tươi mát quá!"
            : "Nhìn cây cối lớn lên đẹp thế! Thật yên bình.";
      case SceneType.aquarium:
        return variant == 0
            ? "Cá đói rồi! Hãy cho chúng ăn nào."
            : "Những người bạn dưới nước đang bơi vui vẻ!";
      case SceneType.paintingRoom:
        return variant == 0
            ? "Sẵn sàng sáng tạo nghệ thuật chưa? Cùng vẽ thôi!"
            : "Mình thích xem tranh của bạn! Hôm nay vẽ gì nhỉ?";
      case SceneType.musicRoom:
        return variant == 0
            ? "Đến lúc sáng tác nhạc! Cùng tạo giai điệu tuyệt vời!"
            : "Âm nhạc xoa dịu tâm hồn! Bạn sẽ chơi gì?";
    }
  }

  // Mascot dialogues - Lời thoại khi đến giờ ngủ (2 biến thể)
  @override
  String getMascotSleepDialogue(int variant) {
    return variant == 0
        ? 'Đến giờ ngủ rồi! Nghỉ ngơi sớm nhé~'
        : 'Tắt màn hình và ngủ ngon nhé 😴';
  }

  // Mascot dialogues - Lời thoại khi click (2 biến thể mỗi scene)
  @override
  String getMascotClickDialogue(SceneType scene, int variant) {
    switch (scene) {
      case SceneType.livingRoom:
        return variant == 0
            ? "Cần giúp sắp xếp công việc không? Mình ở đây!"
            : "Đừng quên nghỉ ngơi và thư giãn nhé!";
      case SceneType.garden:
        return variant == 0
            ? "Làm vườn thư giãn lắm phải không?"
            : "Cây cối lớn tốt hơn khi được yêu thương!";
      case SceneType.aquarium:
        return variant == 0
            ? "Cá là bạn đồng hành tuyệt vời! Nhìn rất thư giãn."
            : "Nhớ cho chúng ăn đều đặn nhé!";
      case SceneType.paintingRoom:
        return variant == 0
            ? "Mọi nghệ sĩ đều từng là người nghiệp dư. Cố lên!"
            : "Màu sắc có thể thể hiện cảm xúc bên trong!";
      case SceneType.musicRoom:
        return variant == 0
            ? "Âm nhạc là ngôn ngữ của cảm xúc!"
            : "Mỗi nốt nhạc bạn chơi đều độc đáo và đặc biệt!";
    }
  }

  // Tutorial - Aquarium
  @override
  String get tutorialAquariumTankDesc => 'Nhấn trực tiếp vào từng con cá để tương tác! Biểu tượng 🍞 nghĩa là cá đang đói — nhấn để cho ăn. Biểu tượng 🪙 nghĩa là có điểm chờ nhận — nhấn để nhận. Thanh nhỏ phía dưới mỗi cá cho thấy tiến trình chu kỳ 20 giờ.';

  @override
  String get tutorialAquariumShopTitle => 'Cửa hàng cá';

  @override
  String get tutorialAquariumShopDesc => 'Mua thêm cá bằng điểm của bạn! Cá đắt tiền hơn sẽ tạo nhiều điểm hơn mỗi giờ. Bạn có thể nuôi tối đa 10 con cá. Bấm nút + để mua và - để bán.';

  // Tutorial - Garden
  @override
  String get tutorialGardenGridDesc => 'Khu vườn 4x4 của bạn! Nhấn vào ô để chăm sóc cây. Nhấn giữ và kéo để thao tác nhiều ô cùng lúc.';

  @override
  String get tutorialGardenInventoryTitle => 'Kho hạt giống';

  @override
  String get tutorialGardenInventoryDesc => 'Chọn loại hạt giống, sau đó nhấn ô trống để trồng. Mỗi loại cây có thời gian lớn và điểm thưởng riêng.';

  // Tutorial - Rock Balancing Lobby
  @override
  String get tutorialRockLobbyConfigTitle => 'Số lượng đá';
  @override
  String get tutorialRockLobbyConfigDesc => 'Chọn số lượng đá. Càng nhiều đá, thử thách càng cao nhưng sáng tạo càng lớn.';
  @override
  String get tutorialRockLobbyRoomTitle => 'Tạo hoặc tham gia';
  @override
  String get tutorialRockLobbyRoomDesc => 'Tạo phòng mới hoặc tìm và Tham gia vào phòng hiện có trong cùng mạng Wi-Fi.';
  @override
  String get tutorialRockLobbyPlayersTitle => 'Người chơi';
  @override
  String get tutorialRockLobbyPlayersDesc => 'Danh sách người chơi. Mọi người cần Sẵn sàng để chủ phòng có thể bắt đầu.';
  @override
  String get tutorialRockLobbyStartTitle => 'Bắt đầu';
  @override
  String get tutorialRockLobbyStartDesc => 'Khi tất cả đã sẵn sàng, chạm đây để bắt đầu.';
  @override
  String get tutorialRockLobbyReadyTitle => 'Sẵn sàng';
  @override
  String get tutorialRockLobbyReadyDesc => 'Chạm để báo hiệu bạn đã sẵn sàng.';

  // Tutorial - Rock Balancing Game
  @override
  String get tutorialRockGameCanvasTitle => 'Xếp chồng đá';
  @override
  String get tutorialRockGameCanvasDesc => 'Kéo đá để xếp chồng. Viền xanh nghĩa là người khác đang giữ viên đá đó.';
  @override
  String get tutorialRockGameCanvasSoloDesc => 'Kéo các viên đá để nhấc lên và đặt chồng lên nhau.';
  @override
  String get tutorialRockGameInfoTitle => 'Kỷ lục';
  @override
  String get tutorialRockGameInfoDesc => 'Độ cao cao nhất được lưu tại đây. Tiếp tục xếp để phá kỷ lục của chính mình!';

  // Tutorial - Firefly Lobby
  @override
  String get tutorialFireflyLobbyConfigTitle => 'Số lượng đom đóm';
  @override
  String get tutorialFireflyLobbyConfigDesc => 'Chọn số đom đóm xuất hiện cùng lúc. Càng nhiều đom đóm, không khí càng nhộn nhịp.';
  @override
  String get tutorialFireflyLobbyRoomTitle => 'Tạo hoặc tham gia';
  @override
  String get tutorialFireflyLobbyRoomDesc => 'Tạo phòng mới hoặc tìm và Tham gia vào phòng hiện có trong cùng mạng Wi-Fi.';
  @override
  String get tutorialFireflyLobbyPlayersTitle => 'Người chơi';
  @override
  String get tutorialFireflyLobbyPlayersDesc => 'Xem danh sách người chơi và vai trò. Mọi người cần Sẵn sàng để chủ phòng có thể bắt đầu.';
  @override
  String get tutorialFireflyLobbyRoleTitle => 'Chọn vai trò';
  @override
  String get tutorialFireflyLobbyRoleDesc => 'Đèn hút/đẩy đom đóm, Lọ dùng để bắt. Có thể đổi vai trò bất kỳ lúc nào.';
  @override
  String get tutorialFireflyLobbyStartTitle => 'Bắt đầu';
  @override
  String get tutorialFireflyLobbyStartDesc => 'Khi tất cả đã sẵn sàng, chạm đây để bắt đầu. Chỉ chủ phòng mới có thể khởi động.';
  @override
  String get tutorialFireflyLobbyReadyTitle => 'Sẵn sàng';
  @override
  String get tutorialFireflyLobbyReadyDesc => 'Chạm để báo hiệu bạn đã sẵn sàng. Chủ phòng sẽ khởi động khi tất cả đã sẵn sàng.';

  // Tutorial - Firefly Game
  @override
  String get tutorialFireflyGameCanvasTitle => 'Di chuyển công cụ';
  @override
  String get tutorialFireflyGameCanvasDesc => 'Chạm để di chuyển công cụ đến vị trí đó.';
  @override
  String get tutorialFireflyGameCanvasSoloDesc => 'Chạm và kéo trực tiếp Đèn hoặc Lọ. Bạn có thể điều khiển cả hai cùng lúc.';
  @override
  String get tutorialFireflyGameCaughtTitle => 'Bắt đom đóm';
  @override
  String get tutorialFireflyGameCaughtDesc => 'Chiếu Đèn làm đom đóm phát sáng, sau đó dùng Lọ hứng lấy chúng.';
  @override
  String get tutorialFireflyGameBrightnessTitle => 'Hút hoặc đẩy';
  @override
  String get tutorialFireflyGameBrightnessDesc => 'Chuyển giữa Hút (đèn mờ) và Đẩy (đèn sáng) để dồn đom đóm về phía Lọ.';
  @override
  String get tutorialFireflyGameSwitchTitle => 'Đổi vai trò';
  @override
  String get tutorialFireflyGameSwitchDesc => 'Chạm để hoán đổi giữa Đèn và Lọ. Hãy phối hợp với đồng đội để có chiến thuật tốt nhất.';
  @override String get tutorialPaperShipGameCanvasTitle => 'Tạo sóng';
  @override String get tutorialPaperShipGameCanvasSoloDesc => 'Chạm vào màn hình để tạo sóng đẩy thuyền đi lên. Chạm nhiều chỗ cùng lúc để tạo nhiều sóng hơn.';
  @override String get tutorialPaperShipGameCanvasDesc => 'Chạm để tạo sóng đẩy thuyền. Mỗi người chơi đóng góp sóng — cùng nhau đưa thuyền đi càng xa càng tốt!';
  @override String get tutorialPaperShipGameInfoTitle => 'Khoảng cách';
  @override String get tutorialPaperShipGameInfoDesc => 'Khoảng cách thuyền đã đi được hiển thị ở đây.';

  @override

  // Breathing Exercise
  @override
  String get breathing => 'Hít thở';

  @override
  String get breathingExercise => 'Bài tập hít thở';

  @override
  String get selectExercise => 'Chọn bài tập';

  @override
  String get exercise478 => 'Hít thở 4-7-8';

  @override
  String get exercise478Desc => 'Thư giãn: Hít 4s, giữ 7s, thở ra 8s';

  @override
  String get exerciseBox => 'Hít thở hộp';

  @override
  String get exerciseBoxDesc => 'Cân bằng: Mỗi giai đoạn 4s';

  @override
  String get exerciseDeepBelly => 'Hít sâu từ bụng';

  @override
  String get exerciseDeepBellyDesc => 'Dịu nhẹ: Hít 5s, giữ 2s, thở ra 6s';

  @override
  String get exerciseCalm => 'Hít thở bình tĩnh';

  @override
  String get exerciseCalmDesc => 'Nhẹ nhàng: Nhịp 4-2-6-2';

  @override
  String get breatheIn => 'Hít vào...';

  @override
  String get breatheOut => 'Thở ra...';

  @override
  String get hold => 'Giữ...';

  @override
  String get pause => 'Tạm dừng...';

  @override
  String get cycles => 'Chu kỳ';

  @override
  String get breathingPraise1 => 'Giỏi lắm!';

  @override
  String get breathingPraise2 => 'Tiếp tục nhé!';

  @override
  String get breathingPraise3 => 'Bạn làm rất tốt!';

  @override
  String get breathingPraise4 => 'Thở đều đi!';

  @override
  String get start => 'Bắt đầu';

  @override
  String get stop => 'Dừng';

  // Sleep Guide
  @override
  String get sleep => 'Giấc ngủ';

  @override
  String get sleepGuide => 'Hướng dẫn giấc ngủ';

  @override
  String get sleepSchedule => 'Lịch ngủ';

  @override
  String get bedtime => 'Giờ đi ngủ';

  @override
  String get wakeTime => 'Giờ thức dậy';

  // Sleep tips
  @override
  String get sleepTipSetBedtime => 'Đặt giờ đi ngủ để nhận gợi ý!';

  @override
  String get sleepTipEarly => 'Còn nhiều thời gian trước giờ ngủ! Cứ tiếp tục nhé 😊';

  @override
  String get sleepTipEarly2 => 'Những thói quen nhỏ mỗi ngày sẽ tích lũy thành giấc ngủ chất lượng hơn.';

  @override
  String get sleepTipEarly3 => 'Ánh sáng tự nhiên ban ngày giúp đồng hồ sinh học của bạn tiết melatonin đúng giờ vào ban đêm.';

  @override
  String get sleepTipEarly4 => 'Uống đủ nước cả ngày giúp cơ thể thoải mái — nhưng hạn chế uống nhiều sát giờ đi ngủ nhé.';

  @override
  String get sleepTipWindDown => 'Đã đến lúc chuẩn bị đi ngủ.';

  @override
  String get sleepTipWindDown2 => 'Thử vươn vai nhẹ hoặc hít thở sâu để chuẩn bị vào giấc ngủ.';

  @override
  String get sleepTipWindDown3 => 'Tắt bớt đèn và tĩnh tâm — giấc ngủ đang đến gần rồi.';

  @override
  String get sleepTipLate => 'Đã quá giờ ngủ! Thử hít thở nhé?';

  @override
  String get sleepTipVeryLate => 'Rất muộn rồi! Nên thư giãn ngay.';

  // Sleep Log (tracking)
  @override
  String get sleepLog => 'Nhật ký giấc ngủ';

  @override
  String get sleepHistory => 'Lịch sử (14 ngày gần nhất)';

  @override
  String get tapDayToLogSleep => 'Chạm vào ngày để ghi lại giấc ngủ';

  @override
  String get actualBedtime => 'Giờ đi ngủ thực tế';

  @override
  String get actualWakeTime => 'Giờ thức dậy thực tế';

  @override
  String get sleepQuality => 'Chất lượng giấc ngủ';

  @override
  String get sleepDuration => 'Thời lượng';

  @override
  String get sleepLogSaved => '✅ Đã lưu nhật ký giấc ngủ!';

  @override
  String get hoursUnit => 'h';

  @override
  String get noSleepData => 'Chưa có dữ liệu giấc ngủ';

  @override
  String get sleepTipsCardTitle => 'Mẹo ngủ ngon';

  @override
  String get sleepTipsLead => 'Có thể bạn đã biết?';

  @override
  String get sleepTip1 => 'Người lớn cần 7–9 giờ ngủ mỗi đêm để duy trì sức khỏe tốt.';

  @override
  String get sleepTip2 => 'Giờ ngủ đều đặn — kể cả cuối tuần — giúp đồng hồ sinh học ổn định hơn.';

  @override
  String get sleepTip3 => 'Giảm độ sáng màn hình và tránh nội dung gây kích thích 30 phút trước khi ngủ để bảo vệ melatonin.';

  @override
  String get sleepTip4 => 'Phòng mát (18–20°C) giúp cơ thể hạ nhiệt, tạo điều kiện cho giấc ngủ sâu.';

  @override
  String get sleepTip5 => 'Caffeine tồn tại trong máu từ 5–7 tiếng — hạn chế uống sau 2 giờ chiều giúp cơ thể dễ đi vào giấc ngủ sâu hơn tối nay.';

  @override
  String get sleepTip6 => 'Một giấc ngủ ngắn 10–20 phút trước 3 giờ chiều giúp tỉnh táo trở lại mà không gây lờ đờ hay ảnh hưởng đến giấc ngủ tối.';

  @override
  String get sleepTip7 => 'Tập thể dục rất tốt cho giấc ngủ — nhưng hãy dành ít nhất 1 giờ để cơ thể hạ nhiệt trước khi lên giường.';

  @override
  String get sleepTip8 => 'Thư giãn ngắn trước khi ngủ giúp não hiểu rằng đã đến giờ nghỉ.';

  @override
  String get sleepTip9 => 'Tránh ăn no trong vòng 2 tiếng trước khi ngủ để tránh khó chịu.';

  @override
  String get sleepTip10 => 'Ghi ra kế hoạch ngày mai trước khi ngủ giúp tâm trí thư thái hơn.';

  @override
  String get sleepLastWeek => 'Tuần trước';

  @override
  String get sleepThisWeek => 'Tuần này';

  // ==================== PROFILE ====================

  @override
  String get menuProfile => 'Hồ sơ';

  @override
  String get editProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get chooseAvatar => 'Chọn avatar';

  // ==================== ACHIEVEMENTS ====================

  @override
  String get achievements => 'Thành tựu';

  @override
  String get achievementsTitle => 'Thành tựu của bạn';

  @override
  String get achievementUnlocked => 'Mở khóa thành tựu!';

  @override
  String get locked => 'Chưa mở khóa';

  @override
  String get goToFeature => 'Đến tính năng';

  @override
  String get tapToDismiss => 'Nhấn để đóng';

  @override
  String achievementUnit(String unitKey) {
    switch (unitKey) {
      case 'days': return 'ngày';
      case 'features': return 'tính năng';
      case 'tasks': return 'công việc';
      case 'entries': return 'nhật ký';
      case 'sessions': return 'phiên';
      case 'logs': return 'lần';
      case 'plants': return 'lần trồng';
      case 'feedings': return 'lần cho ăn';
      case 'pixels': return 'pixel';
      case 'notes': return 'nốt';
      case 'points': return 'điểm';
      default: return unitKey;
    }
  }

  @override
  String achievementCategoryName(String category) {
    switch (category) {
      case 'engagement': return 'Gắn bó';
      case 'schedule': return 'Lập lịch';
      case 'diary': return 'Nhật ký cảm xúc';
      case 'breathing': return 'Hít thở';
      case 'sleep': return 'Giấc ngủ';
      case 'garden': return 'Làm vườn';
      case 'aquarium': return 'Nuôi cá';
      case 'painting': return 'Vẽ tranh';
      case 'music': return 'Âm nhạc';
      case 'score': return 'Điểm thưởng';
      default: return category;
    }
  }

  @override
  String achievementTitle(String id) {
    switch (id) {
      case 'first_steps': return 'Bước đầu tiên';
      case 'app_explorer': return 'Khám phá ứng dụng';
      case 'days_7': return 'Người quen thuộc';
      case 'days_30': return 'Người trung thành';
      case 'first_schedule_task': return 'Công việc đầu tiên';
      case 'schedule_task_15': return 'Bắt đầu kế hoạch';
      case 'schedule_task_75': return 'Người có kỷ luật';
      case 'schedule_task_150': return 'Bậc thầy lịch trình';
      case 'first_diary': return 'Lần đầu viết nhật ký';
      case 'diary_5': return 'Nhật ký mới bắt đầu';
      case 'diary_15': return 'Nhà văn nhật ký';
      case 'diary_30': return 'Nhà văn nội tâm';
      case 'first_breath': return 'Hơi thở đầu tiên';
      case 'breathing_5': return 'Người tìm bình yên';
      case 'breathing_15': return 'Người thở chánh niệm';
      case 'breathing_30': return 'Bậc thầy hơi thở';
      case 'first_sleep_log': return 'Theo dõi giấc ngủ';
      case 'sleep_log_5': return 'Bắt đầu nghỉ ngơi';
      case 'sleep_log_15': return 'Thói quen giấc ngủ';
      case 'sleep_log_30': return 'Chuyên gia giấc ngủ';
      case 'first_plant': return 'Bàn tay xanh';
      case 'plant_30': return 'Người chăm cây non';
      case 'plant_80': return 'Người làm vườn kiên nhẫn';
      case 'plant_160': return 'Nông dân bậc thầy';
      case 'first_fish_fed': return 'Bữa ăn đầu tiên';
      case 'fish_fed_15': return 'Bạn của cá';
      case 'fish_fed_150': return 'Người nuôi cá';
      case 'fish_fed_300': return 'Bậc thầy nuôi cá';
      case 'first_painting': return 'Nét vẽ đầu tiên';
      case 'painting_pixels_512': return 'Họa sĩ tập sự';
      case 'painting_pixels_2560': return 'Bộ sưu tập tranh';
      case 'painting_pixels_5120': return 'Họa sĩ bậc thầy';
      case 'first_music': return 'Nốt nhạc đầu tiên';
      case 'music_notes_60': return 'Giai điệu đầu tiên';
      case 'music_notes_300': return 'Nhạc sĩ tập sự';
      case 'music_notes_600': return 'Nhạc sĩ bậc thầy';
      case 'score_1000': return 'Nghìn điểm';
      case 'score_5000': return 'Người tích lũy';
      case 'score_20000': return 'Huyền thoại điểm số';
      default: return id;
    }
  }

  @override
  String achievementDescription(String id) {
    switch (id) {
      case 'first_steps': return 'Mở ứng dụng lần đầu tiên';
      case 'app_explorer': return 'Thử 3 tính năng khác nhau';
      case 'days_7': return 'Sử dụng ứng dụng trong 7 ngày khác nhau';
      case 'days_30': return 'Sử dụng ứng dụng trong 30 ngày khác nhau';
      case 'first_schedule_task': return 'Hoàn thành công việc đã lên lịch đầu tiên';
      case 'schedule_task_15': return 'Hoàn thành 15 công việc đã lên lịch';
      case 'schedule_task_75': return 'Hoàn thành 75 công việc đã lên lịch';
      case 'schedule_task_150': return 'Hoàn thành 150 công việc đã lên lịch';
      case 'first_diary': return 'Viết mục nhật ký cảm xúc đầu tiên';
      case 'diary_5': return 'Viết 5 mục nhật ký';
      case 'diary_15': return 'Viết 15 mục nhật ký';
      case 'diary_30': return 'Viết 30 mục nhật ký';
      case 'first_breath': return 'Hoàn thành buổi hít thở đầu tiên';
      case 'breathing_5': return 'Hoàn thành 5 buổi hít thở';
      case 'breathing_15': return 'Hoàn thành 15 buổi hít thở';
      case 'breathing_30': return 'Hoàn thành 30 buổi hít thở';
      case 'first_sleep_log': return 'Ghi lại giấc ngủ lần đầu tiên';
      case 'sleep_log_5': return 'Ghi lại giấc ngủ 5 lần';
      case 'sleep_log_15': return 'Ghi lại giấc ngủ 15 lần';
      case 'sleep_log_30': return 'Ghi lại giấc ngủ 30 lần';
      case 'first_plant': return 'Trồng hạt giống đầu tiên';
      case 'plant_30': return 'Trồng cây 30 lần';
      case 'plant_80': return 'Trồng cây 80 lần';
      case 'plant_160': return 'Trồng cây 160 lần';
      case 'first_fish_fed': return 'Cho cá ăn lần đầu tiên';
      case 'fish_fed_15': return 'Cho cá ăn 15 lần';
      case 'fish_fed_150': return 'Cho cá ăn 150 lần';
      case 'fish_fed_300': return 'Cho cá ăn 300 lần';
      case 'first_painting': return 'Tô pixel đầu tiên';
      case 'painting_pixels_512': return 'Tô 512 pixels';
      case 'painting_pixels_2560': return 'Tô 2.560 pixels';
      case 'painting_pixels_5120': return 'Tô 5.120 pixels';
      case 'first_music': return 'Đặt nốt nhạc đầu tiên trong bản nhạc';
      case 'music_notes_60': return 'Đặt 60 nốt nhạc';
      case 'music_notes_300': return 'Đặt 300 nốt nhạc';
      case 'music_notes_600': return 'Đặt 600 nốt nhạc';
      case 'score_1000': return 'Kiếm tổng cộng 1.000 điểm';
      case 'score_5000': return 'Kiếm tổng cộng 5.000 điểm';
      case 'score_20000': return 'Kiếm tổng cộng 20.000 điểm';
      default: return '';
    }
  }
}