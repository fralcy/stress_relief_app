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
  String get fishHungry => 'đói';

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
      case 'harvests': return 'lần thu hoạch';
      case 'claims': return 'lần nhận';
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
      case 'schedule_task_10': return 'Bắt đầu kế hoạch';
      case 'schedule_task_100': return 'Người có kỷ luật';
      case 'schedule_task_300': return 'Bậc thầy lịch trình';
      case 'first_diary': return 'Lần đầu viết nhật ký';
      case 'diary_20': return 'Nhà văn nhật ký';
      case 'diary_50': return 'Nhà văn nội tâm';
      case 'first_breath': return 'Hơi thở đầu tiên';
      case 'breathing_20': return 'Người thở chánh niệm';
      case 'breathing_100': return 'Bậc thầy hơi thở';
      case 'first_sleep_log': return 'Theo dõi giấc ngủ';
      case 'sleep_log_10': return 'Thói quen giấc ngủ';
      case 'sleep_log_30': return 'Chuyên gia giấc ngủ';
      case 'first_harvest': return 'Bàn tay xanh';
      case 'harvest_100': return 'Người làm vườn';
      case 'harvest_300': return 'Nông dân bậc thầy';
      case 'garden_points_1000': return 'Vườn sinh lợi';
      case 'garden_points_5000': return 'Khu vườn phồn thịnh';
      case 'garden_points_10000': return 'Nông trang trù phú';
      case 'first_aquarium_claim': return 'Xu đầu tiên';
      case 'aquarium_points_1000': return 'Bể cá sinh lợi';
      case 'aquarium_points_5000': return 'Đại dương thu nhỏ';
      case 'painting_pixels_512': return 'Họa sĩ tập sự';
      case 'painting_pixels_2560': return 'Bộ sưu tập tranh';
      case 'painting_pixels_5120': return 'Họa sĩ bậc thầy';
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
      case 'schedule_task_10': return 'Hoàn thành 10 công việc đã lên lịch';
      case 'schedule_task_100': return 'Hoàn thành 100 công việc đã lên lịch';
      case 'schedule_task_300': return 'Hoàn thành 300 công việc đã lên lịch';
      case 'first_diary': return 'Viết mục nhật ký cảm xúc đầu tiên';
      case 'diary_20': return 'Viết 20 mục nhật ký';
      case 'diary_50': return 'Viết 50 mục nhật ký';
      case 'first_breath': return 'Hoàn thành buổi hít thở đầu tiên';
      case 'breathing_20': return 'Hoàn thành 20 buổi hít thở';
      case 'breathing_100': return 'Hoàn thành 100 buổi hít thở';
      case 'first_sleep_log': return 'Ghi lại giấc ngủ lần đầu tiên';
      case 'sleep_log_10': return 'Ghi lại giấc ngủ 10 lần';
      case 'sleep_log_30': return 'Ghi lại giấc ngủ 30 lần';
      case 'first_harvest': return 'Thu hoạch cây lần đầu tiên';
      case 'harvest_100': return 'Thu hoạch cây 100 lần';
      case 'harvest_300': return 'Thu hoạch cây 300 lần';
      case 'garden_points_1000': return 'Kiếm 1.000 điểm từ làm vườn';
      case 'garden_points_5000': return 'Kiếm 5.000 điểm từ làm vườn';
      case 'garden_points_10000': return 'Kiếm 10.000 điểm từ làm vườn';
      case 'first_aquarium_claim': return 'Nhận xu từ bể cá lần đầu tiên';
      case 'aquarium_points_1000': return 'Kiếm 1.000 điểm từ bể cá';
      case 'aquarium_points_5000': return 'Kiếm 5.000 điểm từ bể cá';
      case 'painting_pixels_512': return 'Tô 512 pixels';
      case 'painting_pixels_2560': return 'Tô 2.560 pixels';
      case 'painting_pixels_5120': return 'Tô 5.120 pixels';
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