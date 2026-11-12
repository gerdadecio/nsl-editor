# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# A temporary password an administrator can read out over the phone: two
# capitalised common words and two digits, e.g. MapleOtter47.
#
# It meets AD's complexity rule (upper case, lower case, digits) and is at least
# MIN_LENGTH long. AD also refuses a password containing the account name, or
# any part of the display name of three or more characters, so pass those as
# avoid: and no such password is generated.
#
# Words are picked with SecureRandom. With about 600 words and 100 digit pairs
# there are about 36 million passwords: enough for a password that's only
# meant to last until the user changes it, with AD lockout limiting guesses.
class TemporaryPassword
  MIN_LENGTH = 12

  WORDS = %w[
    acorn amber anchor apple apron arch arrow aspen atlas autumn
    badge bamboo banjo barley basket beach beacon beetle berry birch
    biscuit blossom bobcat bonnet border bottle boulder branch bramble breeze
    brick bridge brook bubble bucket buffalo bundle burrow butter button
    cabin cactus camel camera candle canoe canyon carbon carpet carrot
    castle cedar cello chalk cherry chess chimney cider cinder circle
    clover cobalt coconut comet compass copper coral cotton cougar cradle
    crane crater cricket crystal cup cypress daisy dancer delta desert
    dingo dolphin donkey dragon drum dune eagle earth echo eclipse
    elbow elder ember emerald engine falcon feather fennel fern ferry
    fiddle field finch fjord flame flint forest fossil fountain fox
    galaxy garden garnet gecko geyser ginger glacier globe goose granite
    grape gravel grove guitar gully hammock harvest hazel heron
    hickory hill honey hornet husky igloo indigo island ivory
    jacket jaguar jasmine jelly jetty jigsaw jungle kayak kelp kettle
    kiwi koala ladder lagoon lantern larch laurel lemon lentil lichen
    lilac lily linen lizard llama lobster locket lotus magnet
    magpie mango maple marble meadow melon mesa meteor millet mint
    mirror mitten monsoon moose mortar mosaic moss muffin mulberry nectar
    needle nickel nutmeg oasis ocean olive onion opal orange orbit
    orchid osprey otter oyster paddle palm panda papaya parrot parsley
    peach peanut pebble pelican pepper petal pheasant piano pigeon pillow
    pine planet plaster plum pocket pollen pond poppy possum potato
    prairie prism pumpkin puzzle quail quartz quill quince rabbit radish
    raft rainbow raven reef ribbon ridge river robin rocket saddle
    saffron salmon sandal sapling satin scarf season sesame shadow shell
    shovel silver skate sketch sloth socket sorrel spark sparrow spider
    spinach sponge spruce squash squid stable star stone storm summit
    sunset swallow swan tablet tadpole tango teapot thistle thunder tiger
    timber toffee tomato topaz torch tortoise toucan tractor trail tulip
    tundra turnip turtle umbrella valley velvet violet violin volcano wagon
    walnut walrus wattle whale wheat willow window winter wombat yarrow
    zebra zephyr acacia alpine banksia basil beetroot bluebell bracken bunyip
    cassia cockatoo crimson dahlia dewdrop dusk emu eucalypt fig firefly
    galah gumnut gumtree hakea hibiscus ironbark jarrah kookaburra kurrajong lorikeet
    lyrebird mallee mangrove marigold minnow mistral moonbeam myrtle numbat opossum
    paperbark pademelon platypus quokka quoll redgum rosella saltbush sandstone seagrass
    snapdragon spinifex starfish sundew tamarind thornbill tulipwood wallaby waratah wren
    almond anise arbor bay bean beech bloom bough briar bud
    buttercup caper cashew catkin celery chive clove cone cornflower cress
    cumin dill dogwood elm fir flax gourd heather hemlock holly
    hops iris juniper kale lavender leek lime lupin mallow marjoram
    mustard nettle oak oregano pansy pea pear pecan peony primrose
    reed rhubarb rose rosemary rush sage sedge sorghum sprout tansy
    teak thyme vanilla vine wisteria yam zinnia badger beaver bison
    bluejay buzzard canary caribou cheetah chipmunk condor coyote crab dove
    egret ferret flamingo gazelle gibbon gopher grouse hamster hare hawk
    hedgehog ibis impala jackal kestrel kingfisher lark lemur leopard lynx
    marmot marten meerkat mole narwhal newt ocelot oriole owl panther
    penguin petrel pika plover puffin python reindeer salamander seal
    shrew skylark snail stork swift tapir tern thrush toad trout
    vole warbler weasel wildcat woodpecker yak anvil bagel banner barrel
    beret blanket bobbin bonfire bracelet brush cable candy canvas cargo
    carton chapel charcoal chisel clock cloud cobble cookie cork cushion
    dinghy domino easel envelope fabric flannel flute folder fudge funnel
    gadget glider goblet hammer harp helmet hinge kite ladle
    lasso lever marker meadowlark mitre muslin napkin noodle oar paint
    parcel pastel pencil pewter pickle pinwheel pitcher plank pretzel
    pulley quilt radar rattle rocker rudder sail satchel scooter shutter
    sleigh slipper spindle spoon sprocket stencil teacup thimble ticket toggle
    trellis trumpet tunnel tweed wafer whistle wicker zipper
  ].uniq.freeze

  def self.generate(avoid: [])
    new(avoid).generate
  end

  def initialize(avoid)
    @avoid = Array(avoid).flat_map { |text| text.to_s.downcase.split(/[^[:alnum:]]+/) }
      .select { |part| part.length >= 3 }
  end

  def generate
    loop do
      password = candidate
      return password if acceptable?(password)
    end
  end

  private

  def candidate
    words = Array.new(2) { WORDS[SecureRandom.random_number(WORDS.size)].capitalize }
    "#{words.join}#{format("%02d", SecureRandom.random_number(100))}"
  end

  def acceptable?(password)
    password.length >= MIN_LENGTH &&
      @avoid.none? { |part| password.downcase.include?(part) }
  end
end
