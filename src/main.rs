use qtbridge::QApp;

mod backend;
mod document;
mod tokens;

fn main() {
    qtbridge::include_bytes_qml!(
        "../assets/icons/hicolor/scalable/apps/io.github.yukirawa.ShikouEigo.svg",
        "qt/qml/shikou_eigo/icons"
    );
    QApp::new()
        .application_name("試験向英語学習")
        .register::<backend::StudyBackend>()
        .load_qml(include_bytes!("Main.qml"))
        .run();
}
