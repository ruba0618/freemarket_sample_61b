$(document).on('turbolinks:load', function(){ 
// 並びかえ機能、動的チェックボックス機能は未実装です

//   価格のプルダウンを選択時に、最小値と最大値を入力
  $('.detail-search__box').on('change', '#price', function(){
    console.log("OK");
    var price_range = $('#price').val().split(" ");
    console.log(price_range);
    $('#min_price').val(price_range[0]);
    $('#max_price').val(price_range[2]);
  })

// クリアボタンを押すとsubmitする機能を停止させる
// クリア機能は未実装です
  $('.detail-search__box').on('click', '.detail-search__box__form__submit-area--reset', function(){
    return false;
  })
})
