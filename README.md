# nft.third.place-nft

<h2 href="random">Random generator</h2>

Данный контракт используется для получения случайного случайного nft из зараннее загруженной коллекции (В случае с nft.third.place возвращает случайный "кусочек" картины). 

Данный контракт работает по следующему принципу: деплоится контракт с зараннее указанным количеством элементов массива ("кусочков"). Далее необходимо вызвать метод fillParticlesArray. Данный метод был создан для возможности инициализировать массив с большим количеством элементов (Из-за ограничения газа в транзакции сразу не возможно инициализировать и заполнить весь массив). Данный метод добавляет по 100 элементов в динамический массив до того момента, пока массив не будет заполнен полностью. Только после полного заполнения массива с элементами можно будет получать случайный элемент из этого массива. 

Event:

```
    event RandomParticleWasGenerated(address recipient, uint256 particleId); 
```
Создается при вызове метода getRandomParticle, который возвращает случайный "кусочек" картины. <br><br>

Методы:

```
function fillParticlesArray() public onlyOwner checkBalance
```
Используется для обхода ограниченного количества газа в транзакции. Инициализирует массив с id кусочков по 100 за вызов метода. <br><br>

```
function getRandomParticle(address recipient) public onlyOwner checkBalance isActive returns(uint256 particleId)
```
Может быть вызван только после выполнения шага выше. Только после того, как будет полностью массив с id кусочков. Возвращает и удаляет случайный элемент из массива кусочков, а так же создает event RandomParticleWasGenerated. <br><br>

```
function getFreeParticles() public view returns (uint16[] particles)
```
Возвращает массив с оставшимися кусочками. <br><br>

<h2>Проверка случайного распределения кусочков</h2>

Для того, чтобы верифицировать процесс генерации и распределения кусочков картины необходимо использовать graphql по url - https://main.ton.dev/graphql

Для того, чтобы убедиться в том, что полученные кусочки действительно были распределены между их нынешними владельцами необходимо "распарсить" ивенты контракта. Контракт Random Generator доступен по адресу 0:... в mainnet.

Используем следующий код для получения ивентов с контракта:

```
query {
  messages(
  filter:{
    src: { eq: "0:88c6db909884913c48612109a858bfe4a457e55705a7cdec18aacbe26b863fc0" },
    msg_type: {
      eq: 2
    }
  }
  orderBy:{
    path:"created_lt"
    direction:DESC
  }
  )
  {
    body
  }
}
```

Полученные body из ивентов необходимо декодировать, используя следующую команду:

```
tonos-cli decode body --abi <.abi.json file> <msg.body>
```

Например, "распарсим" один ивент, его body:

```
te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA=
```
Декодируем его:

```
tonos-cli decode body --abi RandomGenerator.abi.json "te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA="

```
Получим следующий результат:

```
Config: default
Input arguments:
    body: te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA=
     abi: RandomGenerator.abi.json
RandomParticleWasGenerated: {
  "recipient": "0:c0c6736ecb8cf8dea6bbefbedcb0bff9e439eb0185a9bec2f07c0ecded141377",
  "particleId": "0x0000000000000000000000000000000000000000000000000000000000000018"
}
```

Отсюда следует, что ивент называется RandomParticleWasGenerated и у него такие параметры: recipient и particleId. ParticleID - id "кусочка" картины в шестнадцатеричном формате. Таким образом можно проверить все ивенты и сопоставить с реальным распределением кусочков.

Попробуем найти выпущенный ивент о минтинге у рут контракта:

NftRoot в main сети находится по адресу:

```
0:dc330771f5d1329191ec238ef3d30f05ef949ab97af80af2d07e35ed8fcd4161
```

Воспользуемся уже известным раннее кодом, исправим только адрес:

```
query {
  messages(
  filter:{
    src: { eq: "0:dc330771f5d1329191ec238ef3d30f05ef949ab97af80af2d07e35ed8fcd4161" },
    msg_type: {
      eq: 2
    }
  }
  orderBy:{
    path:"created_lt"
    direction:DESC
  }
  )
  {
    body
  }
}
```

Снова расшифруем поочереди body и найдем ивент создания нашего "кусочка". Путём перебора всех ивентов нашли нужный:

```
msg.id 9b546093ab18f120d3a4813965816ce817c6f5d6f07f15f7a34921229acbd395

Input arguments:
    body: te6ccgEBAgEATQABSwtOO+SAFq+V4BsnankpCWQdKzsRta59CrlulmeXnYppOA4XU77wAQBDgBgYzm3ZcZ8b1Nd999uWF/88hz1gMLU32F4Pgdm9ooJu8A==
     abi: NftRoot.abi.json
tokenWasMinted: {
  "nftAddr": "0:b57caf00d93b53c9484b20e959d88dad73e855cb74b33cbcec5349c070ba9df7",
  "creatorAddr": "0:c0c6736ecb8cf8dea6bbefbedcb0bff9e439eb0185a9bec2f07c0ecded141377"
}
```

Вызовем у nft метод getParticleID для получения порядкового номера "кусочка":

```
tonos-cli --url main.ton.dev run 0:b57caf00d93b53c9484b20e959d88dad73e855cb74b33cbcec5349c070ba9df7 getParticleId '{}' --abi Data.abi.json
```

Получим
```
Input arguments:
 address: 0:b57caf00d93b53c9484b20e959d88dad73e855cb74b33cbcec5349c070ba9df7
  method: getParticleId
  params: {}
     abi: Data.abi.json
    keys: None
lifetime: None
  output: None
Connecting to main.ton.dev
Running get-method...
Succeeded.
Result: {
  "particleId": "0x0000000000000000000000000000000000000000000000000000000000000019"
}
```

Переведем particleId в десятичную систему счисления:
0x19 = 25

Когда мы расшифровывали ивент, который был создан контрактом RandomGenerator мы получили particleId = 24, у этого nft он 25. Это потому что все id в контракте RandomGenerator находятся в промежутке 0..1124, а деплоим nft мы со смещением particleId на 1 т.к. все particleId у nft находятся в диапазоне 1..1025.


<h2>Сведения о сборке контракта</h2>

Данный контракт был собран следующими версиями софта:

<b><a href="https://github.com/tonlabs/tonos-cli/releases/tag/v0.17.19">Tonos_cli</a></b> 0.17.19

COMMIT_ID: abf921f2b14579f1c190edf606b7b51c4c4a2cc3

BUILD_DATE: 2021-08-23 10:10:25 +0000

COMMIT_DATE: 2021-08-21 01:55:38 +0300 

Исходный код <a href="https://github.com/tonlabs/tonos-cli/releases/tag/v0.17.19">тут</a><br><br>

<b><a href="https://github.com/tonlabs/TON-Solidity-Compiler/releases/tag/0.47.0">TON-Solidity-Compiler</a></b>

Version: 0.47.0+commit.44cf54ba.Linux.g++ 

Исходный код <a href="https://github.com/tonlabs/TON-Solidity-Compiler/releases/tag/0.47.0">тут</a><br><br>

<b><a href="https://github.com/tonlabs/TVM-linker/tree/0.13.70">TVM_Linker</a></b> v0.13.20

Исходный код <a href="https://github.com/tonlabs/TVM-linker/tree/0.13.70">тут</a><br><br>

