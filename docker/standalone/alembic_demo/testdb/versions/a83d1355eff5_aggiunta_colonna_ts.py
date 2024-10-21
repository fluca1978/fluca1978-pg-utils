"""Aggiunta colonna ts

Revision ID: a83d1355eff5
Revises: 6852ef9e5362
Create Date: 2024-07-24 13:39:31.198573

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a83d1355eff5'
down_revision: Union[str, None] = '830e787ba6be' #'6852ef9e5362'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column( 'persona',
                   sa.Column( 'ts',
                              sa.DateTime(),
                              server_default = sa.func.current_timestamp() ) )


def downgrade() -> None:
    op.drop_column( 'persona', 'ts' )
