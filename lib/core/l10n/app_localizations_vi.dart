import '../../models/scene_models.dart';
import 'app_localizations.dart';

/// Tiếng Việt
class AppLocalizationsVi extends AppLocalizations {
  @override
  String get appName => 'Giảm Căng Thẳng';
  
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
  String get on => 'BẬT';

  @override
  String get off => 'TẮT';

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
  String get cloudSyncComingSoon => 'Đồng bộ cloud sắp ra mắt!';
  
  @override
  String get resetConfirmation => 'Bạn có chắc muốn đặt lại tất cả cài đặt?';

  @override
  String get scheduleTask => 'Lịch công việc';

  @override
  String get taskName => 'Tên công việc';

  @override
  String get addTask => 'Thêm công việc';
  
  @override
  String get editTask => 'Sửa công việc';

  @override
  String get completed => 'Hoàn thành';
  
  @override
  String get earnPoints => 'Nhận điểm';
                     
  @override
  String get noTasksYet => 'Chưa có công việc nào!';

  @override
  String get enterTaskName => 'Nhập tên công việc';

  @override
  String get taskAdded => 'Đã thêm công việc!';

  @override
  String get taskDeleted => 'Đã xóa công việc!';

  @override
  String get taskUpdated => 'Đã cập nhật công việc!';

  @override
  String get taskNameRequired => 'Vui lòng nhập tên công việc';

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
  String get pointsClaimed => 'Đã nhận điểm!';

  @override
  String get alreadyClaimedOrNoTasks => 'Đã nhận hoặc chưa có công việc hoàn thành!';

  @override
  String get sceneShop => 'Cửa hàng bối cảnh';

  @override
  String get feature => 'Tính năng';

  @override
  String get emotionDiary => 'Nhật ký cảm xúc';

  @override
  String get historyLast2Weeks => 'Lịch sử 2 tuần';

  @override
  String get tapDayToViewDetails => 'Chạm vào ngày để xem chi tiết';

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
  String get journalSaved => '✅ Đã lưu nhật ký!';

  @override
  String get saveToEarnPoints => '✨ Lưu để nhận điểm!';

  @override
  String get alreadySavedToday => '✅ Đã lưu hôm nay';

  // Garden
  @override
  String get gardenTitle => 'KHU VƯỜN';

  @override
  String get inventory => 'KHO ĐỒ';

  @override
  String get action => 'Hành động';

  @override
  String get plant => 'Trồng';

  @override
  String get water => 'Tưới nước';

  @override
  String get pestControl => 'Bắt sâu';

  @override
  String get harvest => 'Thu hoạch';

  @override
  String get plantedSuccessfully => 'Đã trồng thành công!';

  @override
  String get wateredSuccessfully => 'Đã tưới nước!';

  @override
  String get pestControlSuccessfully => 'Đã bắt sâu!';

  @override
  String harvestedSuccessfully(int count, int points) => 'Thu hoạch $count cây! +$points điểm';

  // Aquarium
  @override
  String get fish => 'con cá';

  @override
  String get hour => 'giờ';

  @override
  String get lastFed => 'Cho ăn lần cuối:';

  @override
  String get hoursAgo => 'giờ trước';

  @override
  String get feedNow => 'Cho ăn ngay';

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
  String get readyToFeed => 'Sẵn sàng cho ăn!';

  @override
  String get hoursLeft => 'giờ còn lại';

  @override
  String get claimCoins => 'Nhận xu';

  @override
  String get tankFull => 'BỂ ĐẦY';

  @override
  String get maxFish => 'Tối đa 10 con';

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
  
  @override
  String get selectNote => 'CHỌN NỐT NHẠC';
  
  @override
  String get eraser => 'Tẩy';

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
  String get points => 'điểm';
  
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
  String get japanese => 'Nhật Bản';
  
  @override
  String get winter => 'Mùa đông';

  @override
  String get cozyHomeDesc => 'Những khung cảnh ấm cúng tại nhà';

  @override
  String get forestDesc => 'Khung cảnh rừng xanh yên bình';

  @override
  String get beachDesc => 'Khung cảnh biển thư giãn';

  @override
  String get japaneseDesc => 'Khung cảnh thiền Nhật Bản truyền thống';

  @override
  String get winterDesc => 'Xứ sở mùa đông ấm áp';

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
  String get enterUsername => 'Nhập tên đăng nhập';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get invalidEmail => 'Email không hợp lệ';

  @override
  String get usernameRequired => 'Vui lòng nhập tên đăng nhập';

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
  String get tutorialOverviewTitle => 'Tổng quan - Giao diện & Điều hướng';

  @override
  String get tutorialOverviewDesc => 'Ứng dụng cho phép đồng hành cùng một linh vật mèo dễ thương trong những khoảnh khắc bình yên. Giao diện chính là 5 khu vực của một căn nhà, tương ứng với chúng là các chức năng khác nhau như phòng khách làm trung tâm điều khiển, khu vườn để trồng cây thư giãn, bể cá để nuôi cá và thu thập xu, phòng tranh để sáng tác nghệ thuật, và phòng nhạc để sáng tác âm nhạc. Dùng các nút phía dưới để điều hướng giữa các khu vực.';

  @override
  String get tutorialPointsTitle => 'Hệ thống Điểm & Cửa hàng';

  @override
  String get tutorialPointsDesc => 'Bạn có thể nhận điểm khi làm việc hàng ngày, viết nhật ký hoặc chăm sóc cây cá. Dùng điểm để mua bối cảnh mới cho các phòng.';

  @override
  String get tutorialLifestyleSupportTitle => 'Quản lý Cuộc sống - Nhiệm vụ & Nhật ký';

  @override
  String get tutorialLifestyleSupportDesc => 'Chăm sóc bản thân tốt hơn với công cụ quản lý thời gian và nhật ký cảm xúc. Lập danh sách việc cần làm và nhận thông báo nhắc nhở. Nhật ký đơn giản giúp bạn nhìn lại ngày qua 3 câu hỏi ngắn và ghi chú suy nghĩ.';

  @override
  String get tutorialRewardingTitle => 'Mini-game có thưởng - Vườn & Bể cá';

  @override
  String get tutorialRewardingDesc => 'Minigame giúp bạn nhận điểm. Trồng và chăm sóc cây trong vườn, nuôi cá trong bể và cho chúng ăn định kỳ.';

  @override
  String get tutorialCreativeTitle => 'Mini-game Sáng tạo - Vẽ & Âm nhạc';

  @override
  String get tutorialCreativeDesc => 'Vẽ tranh đơn giản với các màu sắc cơ bản và lưu lại. Phòng nhạc cho phép thử nghiệm với các nốt nhạc từ những nhạc cụ khác nhau.';

  @override
  String get tutorialSettingsTitle => 'Cài đặt & Đồng bộ';

  @override
  String get tutorialSettingsDesc => 'Cài đặt cho phép tùy chỉnh trải nghiệm cá nhân:\n\n• Thay đổi màu sắc chủ đề\n• Chọn ngôn ngữ (Tiếng Việt/English)\n• Điều chỉnh âm lượng nhạc nền và hiệu ứng âm thanh\n• Cài đặt thông báo nhắc nhở\n\nBạn có thể đồng bộ dữ liệu với lưu trữ đám mây để giữ tiến độ tốt hơn thông qua việc đăng ký tài khoản hoặc sử dụng chế độ khách.';

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

  // Theme names
  @override
  String get themePastelBlueBreeze => 'Làn gió xanh dương';

  @override
  String get themeCalmLavender => 'Tím oải hương';

  @override
  String get themeSunnyPastelYellow => 'Vàng nhạt nắng';

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
  String get tutorialAquariumTankDesc => 'Đây là bể cá của bạn! Cá sẽ bơi lượn tự do và tạo ra điểm theo thời gian. Hãy chăm sóc chúng thật tốt!';

  @override
  String get tutorialAquariumFeedTitle => 'Cho cá ăn';

  @override
  String get tutorialAquariumFeedDesc => 'Cho cá ăn mỗi 20 giờ để chúng tiếp tục tạo điểm. Nếu không cho ăn đúng giờ, cá sẽ ngừng tạo điểm! Chú ý thanh tiến trình để biết khi nào cần cho ăn.';

  @override
  String get tutorialAquariumClaimTitle => 'Thu điểm';

  @override
  String get tutorialAquariumClaimDesc => 'Nhấn để thu điểm mà cá đã tạo ra! Mỗi loại cá có tỉ lệ tạo điểm khác nhau. Càng nuôi nhiều cá, càng có nhiều điểm mỗi giờ.';

  @override
  String get tutorialAquariumShopTitle => 'Cửa hàng cá';

  @override
  String get tutorialAquariumShopDesc => 'Mua thêm cá bằng điểm của bạn! Cá đắt tiền hơn sẽ tạo nhiều điểm hơn mỗi giờ. Bạn có thể nuôi tối đa 10 con cá. Bấm nút + để mua và - để bán.';

  // Tutorial - Garden
  @override
  String get tutorialGardenGridDesc => 'Đây là khu vườn 4x4 của bạn! Mỗi ô có thể trồng một cây. Cây sẽ lớn dần theo thời gian và cần được chăm sóc.';

  @override
  String get tutorialGardenInventoryTitle => 'Kho hạt giống';

  @override
  String get tutorialGardenInventoryDesc => 'Kho hạt giống của bạn! Chọn loại hạt bạn muốn trồng. Mỗi loại cây có thời gian lớn và điểm thưởng khác nhau.';

  @override
  String get tutorialGardenActionsTitle => 'Hành động';

  @override
  String get tutorialGardenActionsDesc => 'Các hành động: Trồng cây mới (cần chọn loại cây trong kho hạt giống), Tưới nước khi cây khát, Trừ sâu khi bị sâu bệnh, Thu hoạch khi cây đã chín. Chọn hành động rồi chạm vào ô đất tương ứng!';

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

  @override
  String get sleepTimer => 'Hẹn giờ ngủ';

  @override
  String get timerDuration => 'Thời lượng';

  @override
  String get startTimer => 'Bắt đầu';

  @override
  String get stopTimer => 'Dừng lại';

  @override
  String get musicWillFadeOut => 'Nhạc sẽ nhỏ dần và tắt';

  @override
  String get troubleSleeping => 'Khó ngủ?';

  @override
  String get tryBreathingExercise => 'Thử bài tập hít thở để thư giãn';

  @override
  String get goToBreathing => 'Đến Hít thở';

  // Sleep tips
  @override
  String get sleepTipSetBedtime => 'Đặt giờ đi ngủ để nhận gợi ý!';

  @override
  String get sleepTipEarly => 'Còn nhiều thời gian trước giờ ngủ!';

  @override
  String get sleepTipWindDown => 'Đã đến lúc chuẩn bị đi ngủ.';

  @override
  String get sleepTipLate => 'Đã quá giờ ngủ! Thử hít thở nhé?';

  @override
  String get sleepTipVeryLate => 'Rất muộn rồi! Nên thư giãn ngay.';

  // Sleep Log (tracking)
  @override
  String get sleepLog => 'Nhật ký giấc ngủ';

  @override
  String get sleepHistory => 'Lịch sử (7 ngày gần nhất)';

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
}